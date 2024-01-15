# Hey Emacs, use -*- Tcl -*- mode

set thisfile [file normalize [info script]]

set test_directory [file dirname $thisfile]

set invoked_directory [pwd]

set test_directory_parts [file split $test_directory]
set package_directory [file join {*}[lrange $test_directory_parts 0 end-1] package]

lappend auto_path $package_directory

######################## Command line parsing ########################
#
# Get cmdline from tcllib
package require cmdline

set usage "usage: [file tail $argv0] \[options]"
set options {
    {v.arg 0.0 "Version to test"}
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


########################## Main entry point ##########################

test_require
