# Hey Emacs, use -*- Tcl -*- mode

set thisfile [file normalize [info script]]

set test_directory [file dirname $thisfile]

set invoked_directory [pwd]

set test_directory_parts [file split $test_directory]
set package_directory [file join {*}[lrange $test_directory_parts 0 end-1] package]

lappend auto_path $package_directory

proc iterint {start points} {
    # Return a list of increasing integers starting with start with
    # length points
    set count 0
    set intlist [list]
    while {$count < $points} {
	lappend intlist [expr $start + $count]
	incr count
    }
    return $intlist
}

######################## Command line parsing ########################
#
# Get cmdline from tcllib
package require cmdline

set usage "usage: [file tail $argv0] \[options]"
set options {
    {v.arg 0.0 "Version to test"}
    {n.arg "mypackage" "Name of the package"}
}

# Serial numbers
#
# We'll infer the number of attached devices from the number of serial numbers entered.
foreach reference [iterint 1 10] {
    lappend options [list sn${reference}.arg "" "Serial number of any attached ADU100"]
}

try {
    array set params [::cmdline::getoptions argv $options $usage]
} trap {CMDLINE USAGE} {message optdict} {
    # Trap the usage signal, print the message, and exit the application.
    # Note: Other errors are not caught and passed through to higher levels!
    puts $message
    exit 1
}

proc colorputs {newline text color} {

    set colorlist [list black red green yellow blue magenta cyan white]
    set index 30
    foreach fgcolor $colorlist {
	set ansi(fg,$fgcolor) "\033\[1;${index}m"
	incr index
    }
    set ansi(reset) "\033\[0m"
    switch -nocase $color {
	"red" {
	    puts -nonewline "$ansi(fg,red)"
	}
	"green" {
	    puts -nonewline "$ansi(fg,green)"
	}
	"yellow" {
	    puts -nonewline "$ansi(fg,yellow)"
	}
	"blue" {
	    puts -nonewline "$ansi(fg,blue)"
	}
	"magenta" {
	    puts -nonewline "$ansi(fg,magenta)"
	}
	"cyan" {
	    puts -nonewline "$ansi(fg,cyan)"
	}
	"white" {
	    puts -nonewline "$ansi(fg,white)"
	}
	default {
	    puts "No matching color"
	}
    }
    switch -exact $newline {
	"-nonewline" {
	    puts -nonewline "$text$ansi(reset)"
	}
	"-newline" {
	    puts "$text$ansi(reset)"
	}
    }

}

proc listns {{parentns ::}} {
    set result [list]
    foreach ns [namespace children $parentns] {
        lappend result {*}[listns $ns] $ns
    }
    return $result
}

proc fail_message { message } {
    # Print a fail message
    puts -nonewline "\["
    colorputs -nonewline "fail" red
    puts -nonewline "\] "
    puts $message
}

proc pass_message { message } {
    # Print a pass message
    puts -nonewline "\["
    colorputs -nonewline "pass" green
    puts -nonewline "\] "
    puts $message
}

proc info_message { message } {
    # Print an informational message
    puts -nonewline "\["
    colorputs -nonewline "info" blue
    puts -nonewline "\] "
    puts $message
}

proc indented_message { message } {
    # Print a message indented to the end of a pass/fail block
    foreach character [iterint 0 7] {
	puts -nonewline " "
    }
    puts $message
}

namespace eval libusb_errors {
    variable timeout -7
}




proc test_require {} {
    # Test requiring the package and the package version
    global params
    info_message "Test loading package"
    try {
	set version [package require -exact $params(n) $params(v)]
    } trap {} {message optdict} {
	fail_message "Failed to load $params(n) package"
	indented_message "$message"
	exit
    }
    if {$version eq $params(v)} {
	pass_message "Loaded $params(n) version $version"
	set action_script [package ifneeded $params(n) $version]
	foreach line [split $action_script "\n"] {
	    indented_message $line
	}
	return
    } else {
	fail_message "Failed to load correct $params(n) version"
	indented_message "Expected $params(v), got $version"
	exit
    }


}

proc test_discovered_devices {} {
    # Test that the software finds the correct number of devices
    #
    # This is the last test that expects a potential hardware failure
    global params
    info_message "Testing device discovery"
    set devices_to_find 0
    foreach sernum [iterint 1 10] {
	if { $params(sn$sernum) ne "" } {
	    incr devices_to_find
	}
    }
    set discovered_devices [tcladu::discovered_devices]
    if {$discovered_devices < 0} {
	fail_message "Discovery failed, error code $discovered_devices"
	exit
    }
    if {$discovered_devices == 0} {
	fail_message "No ADU100s found"
	exit
    }
    if {$discovered_devices == $devices_to_find} {
	pass_message "Found $discovered_devices ADU100, expected $devices_to_find"
	return
    }

}

proc test_serial_numbers {} {
    # Test that the connected devices show the expected serial numbers
    global params
    foreach sernum [iterint 1 10] {
	if { $params(sn$sernum) ne "" } {
	    lappend expected_number_list $params(sn$sernum)
	}
    }
    set index 0
    # set found_number_list [serial_number_list]
    set found_number_list [tcladu::serial_number_list]
    # Found serial numbers can come in any order
    foreach sernum $expected_number_list {
	if {[lsearch -exact $found_number_list $sernum] < 0} {
	    fail_message "Did not find $sernum in the discovered list: $found_number_list"
	    exit
	}
    }
    pass_message "Found serial numbers $found_number_list, expected $expected_number_list"
    return
}

proc test_initializing_device {} {
    # Test claiming interface 0 on an ADU100
    global params
    set result [tcladu::initialize_device 0]
    if { $result == 0 } {
	pass_message "Initialized ADU100 0"
    } else {
	fail_message "Failed to initialize ADU100 0, return value $result"
	exit
    }
    return
}

proc test_writing_to_device {} {
    # Test writing to ADU100 0
    global params
    info_message "Test writing to device"

    # CPA1111 is the command to make all digital ports inputs.  There's no response.
    set command "CPA1111"

    # send_command will always return a list of [success_code,
    # elapsed_ms], even when there's an error.
    # set result [send_command 0 $command]
    set result [tcladu::send_command 0 $command]
    set elapsed_ms [lindex $result 1]
    if { [lindex $result 0] == 0 } {
	pass_message "Wrote '$command' to ADU100 0 in $elapsed_ms ms"
    } else {
	fail_message "Failed to write '$command' to ADU100 0, return value $result"
	exit
    }
    return
}

proc test_clearing_queue {} {
    # Test clearing the output queue
    info_message "Test clearing the queue"
    set result [tcladu::clear_queue 0]
    if { [lindex $result 0] == 0 } {
	pass_message "Cleared ADU100 0 in [lindex $result 1] ms"
    } else {
	fail_message "Failed to clear ADU100 0, return value $result"
	exit
    }
    return
}

proc test_reading_from_device {} {
    # Test reading from ADU100 0
    global params
    info_message "Test reading from device"

    # RPK0 queries the status of relay K0
    set command "RPK0"
    set result [tcladu::query 0 $command]
    # query will always return a list of [success_code,
    # query response, elapsed_ms], even when there's an error.
    if { [lindex $result 0] == 0 } {
	set elapsed_ms [lindex $result 2]
	pass_message "Read [lindex $result 1] from ADU100 0 after '$command' query in $elapsed_ms ms"
    } else {
	fail_message "Failed to read from ADU100 0"
	exit
    }
    return
}

proc test_closing_relay {} {
    global params
    info_message "Test closing relay"
    # SK0 "sets" (closes) relay contact 0, the only relay
    set result [tcladu::send_command 0 "SK0"]
    set success_code [lindex $result 0]
    set elapsed_ms [lindex $result 1]
    if { $success_code == 0 } {
	pass_message "Wrote 'SK0' to ADU100 0 in $elapsed_ms ms"
    } else {
	fail_message "Failed to write 'SK0' to ADU100 0"
	exit
    }

    # RPK0 queries the status of relay 0
    set result [tcladu::query 0 "RPK0"]
    set success_code [lindex $result 0]
    set response [lindex $result 1]
    set elapsed_ms [lindex $result 2]

    if { $success_code == 0 && $response == 1 } {
	pass_message "'RPK0' query confirms closed (set) relay in $elapsed_ms ms"
    }

    # Reset the relay
    info_message "Openning relay"
    set result [tcladu::send_command 0 "RK0"]

    set result [tcladu::query 0 "RPK0"]
    set success_code [lindex $result 0]
    set response [lindex $result 1]
    set elapsed_ms [lindex $result 2]
    if { $success_code == 0 && $response == 0 } {
	pass_message "'RPK0' query confirms open (reset) relay in $elapsed_ms ms"
    }
}

proc test_long_query {} {
    global params
    info_message "Test query taking a long time to return"
    # 'RUC00' requests a calibration of AN0, then asks for the measurement
    set command "RUC00"
    set result [tcladu::query 0 $command]
    set success_code [lindex $result 0]
    set response [lindex $result 1]
    set elapsed_ms [lindex $result 2]
    if { $success_code == 0 } {
	pass_message "'$command' query returned $response in $elapsed_ms ms" 
    }
}

########################## Main entry point ##########################

test_require

listns

test_discovered_devices
test_serial_numbers
test_initializing_device

test_clearing_queue


# Reading and writing have to be done in pairs
test_writing_to_device

test_reading_from_device

test_closing_relay

test_long_query
