# Hey Emacs, use -*- Tcl -*- mode

# SWIG configures the package name, namespace, and version number.  We
# need to extract this version number from the package binary.
#
# dir is a variable set by Tcl's auto loader as it traverses the
# auto_path.  See
# Practical Programming in Tcl/Tk by Welch and Jones
if [info exists dir] {
    # The auto loader is running
    load [file join $dir tcladu.so]    
} else {
    # pkg_mkIndex is running
    load ./tcladu.so
}

set version [package present tcladu]
package provide tcladu $version

namespace eval libusb_errors {
    variable timeout -7
}


namespace eval tcladu {

    
    proc serial_number_list {} {
	# Return a list of connected serial numbers
	foreach index [iterint 0 [tcladu::discovered_devices]] {
	    lappend serial_number_list [tcladu::serial_number $index]
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
	set success_code [tcladu::write_device $index $command $timeout_ms]
	set elapsed_ms [expr [clock clicks -millisec] - $t0]
	return [list $success_code $elapsed_ms]
    }

    proc query { index command } {
	# Send a command and return a list of response, elapsed time
	#
	# Arguments:
	#   index -- Which ADU100 to target.  0,1,...(connected ADU100s -1)
	#   command -- The ASCII command to send
	set timeout_ms 200
	set t0 [clock clicks -millisec]
	# Assume that send command will work perfectly
	tcladu::send_command $index $command
	foreach trial [iterint 0 100] {
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
		$libusb_errors::timeout {
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
	# Clear the ADU100's output message queue
	#
	# Arguments:
	#   index -- Which ADU100 to target.  0,1,...(connected ADU100s -1)
	set timeout_ms 10
	set t0 [clock clicks -millisec]
	foreach trial [iterint 0 10] {
	    set result [tcladu::read_device 0 8 $timeout_ms]
	    if {[lindex $result 0] == -7} {
		# The device has timed out, so the queue is empty
		return
	    }
	}

    }
}


