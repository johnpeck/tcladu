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
}


