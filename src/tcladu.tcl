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

    proc force_integer { raw_integer } {
	# Returns integers with leading zeros stripped off.
	# https://stackoverflow.com/questions/2110864/handling-numbers-with-leading-zeros-in-tcl
	# Arguments:
	#
	#   raw_integer -- Integer input maybe with leading zeros
	set count [scan $raw_integer %d%s clean_integer rest]
	if { $count <= 0 || ( $count == 2 && ![string is space $rest] ) } {
	    return -code error "not an integer: \"$x\""
	}
	return $clean_integer
    }


    proc error_decode { error_code } {
	# Return a dictionary of error parameters based on the integer
	# returned by the low-level functions.
	#
	# Arguments:
	#   error_code -- The integer error return from a low-level function
	set error_dict [dict create]
	switch $error_code {
	    0 {
		dict set error_dict code "LIBUSB_SUCCESS"
		dict set error_dict message "Success"
	    }
	    -1 {
		dict set error_dict code "LIBUSB_ERROR_IO"
		dict set error_dict message "libusb I/O error"
	    }
	    -2 {
		dict set error_dict code "LIBUSB_ERROR_INVALID_PARAM"
		dict set error_dict message "libusb error: invalid parameter"
	    }
	    -3 {
		dict set error_dict code "LIBUSB_ERROR_ACCESS"
		dict set error_dict message "libusb error: access denied (insufficient permissions)"
	    }
	    -4 {
		dict set error_dict code "LIBUSB_ERROR_NO_DEVICE"
		dict set error_dict message "libusb error: no such device -- it might have been disconnected"
	    }
	    -5 {
		dict set error_dict code "LIBUSB_ERROR_NOT_FOUND"
		dict set error_dict message "libusb error: not found"
	    }
	    -6 {
		dict set error_dict code "LIBUSB_ERROR_BUSY"
		dict set error_dict message "libusb error: busy"
	    }
	    -7 {
		dict set error_dict code "LIBUSB_ERROR_TIMEOUT"
		dict set error_dict message "libusb error: operation timed out"
	    }
	    -8 {
		dict set error_dict code "LIBUSB_ERROR_OVERFLOW"
		dict set error_dict message "libusb error: overflow"
	    }
	    -9 {
		dict set error_dict code "LIBUSB_ERROR_PIPE"
		dict set error_dict message "libusb error: pipe"
	    }
	    -10 {
		dict set error_dict code "LIBUSB_ERROR_INTERRUPTED"
		dict set error_dict message "libusb error: system call interrupted"
	    }
	    -11 {
		dict set error_dict code "LIBUSB_ERROR_NO_MEM"
		dict set error_dict message "libusb error: insufficient memory"
	    }
	    -12 {
		dict set error_dict code "LIBUSB_ERROR_NOT_SUPPORTED"
		dict set error_dict message "libusb error: operation not supported or unimplemented on this platform"
	    }
	    -20 {
		dict set error_dict code "ADU100_COMMAND_SIZE"
		dict set error_dict message "Command too large for USB transfer buffer"
	    }
	    -21 {
		dict set error_dict code "ADU100_READ_SIZE"
		dict set error_dict message "read_device: can't read less than 8 characters"
	    }
	    -99 {
		dict set error_dict code "LIBUSB_ERROR_OTHER"
		dict set error_dict message "libusb error: other"
	    }
	}
	return $error_dict
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
	    error [tcladu::error_decode $retval] 
	}
	# If we made it here, everything was fine
	return 0
    }

    proc write_device { index command timeout_ms } {
	# Calls the low-level write_device, throwing an error if necessary
	#
	# Arguments:
	#   index -- Which ADU100 to target.  0,1,...(connected ADU100s -1)
	#   command -- ASCII command to write
	#   timeout_ms -- How long libusb should wait for an acknowledgement (ms)
	set retval [tcladu::_write_device $index $command $timeout_ms]
	if { $retval == -20 } {
	    error "write_device: command $command is too large for transfer buffer"
	} elseif { $retval < 0 } {
	    error [tcladu::error_decode $retval]
	}
	# If we made it here, everything was fine
	return 0
    }

    proc read_device { index chars timeout_ms } {
	# Calls the low-level read_device, throwing an error if necessary
	#
	# Arguments:
	#   index -- Which ADU100 to target.  0,1,...(connected ADU100s -1)
	#   chars -- How many characters (must be more than 8) to read
	#   timeout_ms -- How long libusb should wait for the expected characters (ms)
	set retval [tcladu::_read_device $index $chars $timeout_ms]
	# The low-level _read_device will return a list even if the
	# read fails.
	set success_code [lindex $retval 0]
	if { $success_code == -21 } {
	    error "read_device: $chars characters is less than the minimum 8"
	} elseif { $success_code < 0 } {
	    set error_dict [tcladu::error_decode $success_code]
	    set message [dict get $error_dict message]
	    set code [dict get $error_dict code]
	    throw $code $message
	}
	# If we made it here, the return will be a list of
	# 1 -- 0 (success)
	# 2 -- the characters read from the device
	return $retval
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
	set retries 100
	set t0 [clock clicks -millisec]
	# Assume that send command will work perfectly
	tcladu::send_command $index $command
	foreach trial [tcladu::iterint 0 $retries] {
	    try {
		set result [tcladu::read_device 0 8 $timeout_ms]
	    } trap {LIBUSB_ERROR_TIMEOUT} {message optdict} {
		# We timed out, but it's a libusb timeout and not
		# something from the ADU100.  We likely just need to
		# wait longer for a response.
		continue
	    } trap {} {message optdict} {
		# Some other error we can't handle.  This is fatal.
		puts "Querying '$command' from device $index failed.  Message is: $message"
		exit
	    }
	    # Query has succeeded, return the result
	    set elapsed_ms [expr [clock clicks -millisec] - $t0]
	    set success_code [lindex $result 0]
	    set raw_response [lindex $result 1]
	    # Strip leading zeros
	    set clean_response [force_integer $raw_response]
	    return [list $success_code $clean_response $elapsed_ms]

	}
	# If we get here, we've exceeded the maximum query attempts.  This is fatal.
	set message "Querying device $index with $command failed after $retries attempts"
	throw {TCLADU QUERY RETRIES} $message
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
	    try {
		set result [tcladu::read_device 0 8 $timeout_ms]		
	    } trap {LIBUSB_ERROR_TIMEOUT} {message optdict} {
		# We timed out, so the queue is empty.  Set the
		# success code to zero to indicate that the queue was
		# clearerd OK.
		set elapsed_ms [expr [clock clicks -millisec] - $t0]
		return [list 0 $elapsed_ms]
	    } trap {} {message optdict} {
		# We can't clear the Tx queue
		set message "Unable to clear the transmit buffer.  Message is: $message"
		throw {TCLADU CLEAR_QUEUE OTHER} $message
	    }
	}
    }
}


