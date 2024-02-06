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

proc indented_message { message } {
    # Print a message indented to the end of a pass/fail block
    foreach character [iterint 0 7] {
	puts -nonewline " "
    }
    puts $message
}

proc serial_number_list {} {
    # Return a list of connected serial numbers
    #
    # Must run discovered_devices before this works
    foreach index [iterint 0 10] {
	if { [string length [adu100::serial_number $index]] > 2 } {
	    # Empty serial numbers will return {}, which has a string length of 2
	    lappend serial_number_list [adu100::serial_number $index]
	}
    }
    return $serial_number_list
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



########################## Main entry point ##########################

test_require
test_discovered_devices
test_serial_numbers
