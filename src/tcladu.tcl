# Hey Emacs, use -*- Tcl -*- mode

set this_file [file normalize [info script]]
set this_directory [file dirname $this_file]

# SWIG configures the package name, namespace, and version number.  We
# need to extract this version number from the package binary.
#
# dir is a variable set by Tcl's auto loader as it traverses the
# auto_path.  See
# Practical Programming in Tcl/Tk by Welch and Jones
load [file join $this_directory tcladu.so]

set version [package present tcladu]
package provide tcladu $version

namespace eval libusb_errors {
    variable timeout -7
}




namespace eval tcladu {

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

    proc libusb_error_string { error_code } {
	# Return a string representation of the libusb error
	#
	# Arguments:
	#   error_code -- The integer return from a libusb function
	switch $error_code {
	    0 {
		return "libusb success"
	    }
	    -1 {
		return "libusb I/O error"
	    }
	    -2 {
		return "libusb error: invalid parameter"
	    }
	    -3 {
		return "libusb error: access"
	    }
	    -4 {
		return "libusb error: no device"
	    }
	    -5 {
		return "libusb error: not found"
	    }
	    -6 {
		return "libusb error: busy"
	    }
	    -7 {
		return "libusb error: timeout"
	    }
	    -8 {
		return "libusb error: overflow"
	    }
	    -9 {
		return "libusb error: pipe"
	    }
	    -10 {
		return "libusb error: interrupted"
	    }
	    -11 {
		return "libusb error: no memory"
	    }
	    -12 {
		return "libusb error: not supported"
	    }
	    -99 {
		return "libusb error: other"
	    }
	}
    }

    
    proc serial_number_list {} {
	# Return a list of connected serial numbers
	set serial_number_list [list]
	foreach index [tcladu::iterint 0 [tcladu::discovered_devices]] {
	    lappend serial_number_list [tcladu::serial_number $index]
	}
	return $serial_number_list
    }

    proc initialize_device { index } {
	# Calls the low-level initialize_device, throwing an error if necessary
	#
	# Arguments:
	#   index -- Which ADU100 to target.  0,1,...(connected ADU100s -1)
	set retval [tcladu::_initialize_device $index]
	if { $retval < 0 } {
	    error [tcladu::libusb_error_string $retval] 
	}
	# If we made it here, everything was fine
	return 0
    }

    proc send_command { index command } {
	# Send a command and return a list of success code, elapsed time
	#
	# Arguments:
	#   index -- Which ADU100 to target.  0,1,...(connected ADU100s -1)
	#   command -- The ASCII command to send
	set timeout_ms 200

	set t0 [clock clicks -millisec]
	set success_code [tcladu::write_device $index $command $timeout_ms]
	set elapsed_ms [expr [clock clicks -millisec] - $t0]
	return [list $success_code $elapsed_ms]
    }

    proc query { index command } {
	# Send a command and return a list of success code, response, elapsed time
	#
	# Arguments:
	#   index -- Which ADU100 to target.  0,1,...(connected ADU100s -1)
	#   command -- The ASCII command to send
	set timeout_ms 200
	set t0 [clock clicks -millisec]
	# Assume that send command will work perfectly
	tcladu::send_command $index $command
	foreach trial [tcladu::iterint 0 100] {
	    set result [tcladu::read_device $index 8 $timeout_ms]
	    set success_code [lindex $result 0]
	    switch $success_code {
		0 {
		    # Query has succeeded, return the result
		    set elapsed_ms [expr [clock clicks -millisec] - $t0]
		    set success_code [lindex $result 0]
		    set response [lindex $result 1]
		    return [list $success_code $response $elapsed_ms]
		}
		-7 {
		    # Query has timed out, but it's because of a libusb
		    # timeout -- not the device.  We likely just need to
		    # wait longer for the device to respond.
		    continue
		}
	    }
	}
	return -1
    }

    proc clear_queue { index } {
	# Clear the ADU100's output message queue, returning success
	# code and elapsed time
	#
	# Arguments:
	#   index -- Which ADU100 to target.  0,1,...(connected ADU100s -1)
	set timeout_ms 10
	set t0 [clock clicks -millisec]
	foreach trial [tcladu::iterint 0 10] {
	    set result [tcladu::read_device 0 8 $timeout_ms]
	    set success_code [lindex $result 0]
	    # Note that switch statements won't do variable resolution
	    # -- we need fixed alternatives.
	    switch $success_code {
		0 {
		    # We were able to read something, so the device's
		    # output queue is not empty.
		    continue
		}
		-7 {
		    # We timed out, so the queue is empty.  Set the
		    # success code to zero to indicate that the queue
		    # was clearerd OK.
		    set elapsed_ms [expr [clock clicks -millisec] - $t0]
		    return [list 0 $elapsed_ms]
		}
	    }
	}
	# If we made it here, there's some other error
	return -code error "Expected libusub timeout error $libusb_errors::timeout, got $success_code"
    }


}


