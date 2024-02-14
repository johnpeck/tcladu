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

proc serial_number_list {} {
    # Return a list of connected serial numbers
    foreach index [iterint 0 [adu100::discovered_devices]] {
	lappend serial_number_list [adu100::serial_number $index]
    }
    return $serial_number_list
}

proc send_command { index command } {
    # Send a command and return a list of success code, elapsed time
    #
    # Arguments:
    #   index -- Which ADU100 to target.  0,1,...(connected ADU100s -1)
    #   command -- The ASCII command to send
    set timeout_ms 200

    set t0 [clock clicks -millisec]
    set success_code [adu100::write_device $index $command $timeout_ms]
    set elapsed_ms [expr [clock clicks -millisec] - $t0]
    indented_message "Received success code from adu100::write_device sending $command in $elapsed_ms ms"
    return [list $success_code $elapsed_ms]
}

proc read_response { index } {
    set timeout_ms 200
    set t0 [clock clicks -millisec]
    foreach trial [iterint 0 100] {
	set result [adu100::read_device $index 8 200]
	if {[lindex $result 0] == 0} {
	    puts "Received $result from adu100::read_device in [expr [clock clicks -millisec]-$t0] ms"
	    return $result
	}
    }
    return -1
}

proc query { index command } {
    set timeout_ms 200
    set t0 [clock clicks -millisec]
    # Assume that send command will work perfectly
    send_command $index $command
    foreach trial [iterint 0 100] {
	set result [adu100::read_device $index 8 $timeout_ms]
	if {[lindex $result 0] == 0} {
	    set elapsed_ms [expr [clock clicks -millisec] - $t0]
	    set success_code [lindex $result 0]
	    set response [lindex $result 1]
	    return [list $success_code $response $elapsed_ms]
	    
	    # puts "Received $result from $command query in [expr [clock clicks -millisec]-$t0] ms"
	    # return $result
	}
    }
    return -1
}

proc clear_queue { index } {
    info_message "Clearing ADU100 $index output queue"
    set timeout_ms 10
    set t0 [clock clicks -millisec]
    foreach trial [iterint 0 10] {
	set result [adu100::read_device 0 8 $timeout_ms]
	if {[lindex $result 0] == -7} {
	    # The device has timed out, so the queue is empty
	    indented_message "Received $result from adu100::read_device after clearing queue in [expr [clock clicks -millisec]-$t0] ms"
	    return
	}
    }

}

proc test_require {} {
    # Test requiring the package and the package version
    global params

    try {
	set version [package require adutcl]
    } trap {} {message optdict} {
	fail_message "Failed to load adutcl package"
	indented_message "$message"
	exit
    }
    if {$version eq $params(v)} {
	pass_message "Loaded adutcl version $version"
	return
    } else {
	fail_message "Failed to load correct adutcl version"
	indented_message "Expected $params(v), got $version"
	exit
    }

}

proc test_discovered_devices {} {
    # Test that the software finds the correct number of devices
    #
    # This is the last test that expects a potential hardware failure
    global params
    set devices_to_find 0
    foreach sernum [iterint 1 10] {
	if { $params(sn$sernum) ne "" } {
	    incr devices_to_find
	}
    }
    set discovered_devices [adu100::discovered_devices]
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
    set found_number_list [serial_number_list]
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
    set result [adu100::initialize_device 0]
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
    set result [send_command 0 $command]
    set elapsed_ms [lindex $result 1]
    if { [lindex $result 0] == 0 } {
	pass_message "Wrote '$command' to ADU100 0 in $elapsed_ms ms"
    } else {
	fail_message "Failed to write '$command' to ADU100 0, return value $result"
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
    set result [query 0 $command]
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
    # SK0 "sets" (closes) relay contact 0, the only relay
    set result [send_command 0 "SK0"]
    set success_code [lindex $result 0]
    set elapsed_ms [lindex $result 1]
    if { $success_code == 0 } {
	pass_message "Wrote 'SK0' to ADU100 0 in $elapsed_ms ms"
    } else {
	fail_message "Failed to write 'SK0' to ADU100 0"
	exit
    }

    # RPK0 queries the status of relay 0
    set result [query 0 "RPK0"]
    # set result [send_command 0 "RPK0"]
    # set result [read_response 0]

    if { [lindex $result 0] == 0 && [lindex $result 1] == 1 } {
	pass_message "Closed relay"
    }

    # Reset the relay
    set result [send_command 0 "RK0"]

    set result [query 0 "RPK0"]
    if { [lindex $result 0] == 0 && [lindex $result 1] == 0 } {
	pass_message "Reset (opened) relay"
    }
}

########################## Main entry point ##########################

test_require

test_discovered_devices
test_serial_numbers
test_initializing_device

clear_queue 0

# Reading and writing have to be done in pairs
test_writing_to_device

test_reading_from_device

test_closing_relay
