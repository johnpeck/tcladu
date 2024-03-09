# Hey Emacs, use -*- Tcl -*- mode

# SWIG configures the package name, namespace, and version number.  We
# need to extract this version number from the package binary.
load ./tcladu.so
set version [package present tcladu]
package provide tcladu $version

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
}


