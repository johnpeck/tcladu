// SWIG interface definition

// Name of this module -- not the namespace prefix.  See the makefile
// for how to set the namespace.
%module adutcl

// Provides cstring_bounded_output allowing functions to return C strings to Tcl 
%include cstring.i

%{
  // Put header files here or function declarations like below
  #include <libusb-1.0/libusb.h>
  int initialize();
  libusb_device_handle *  open_device(int vid, int pid);
  int write_to_adu( libusb_device_handle * device_handle, const char * _cmd, int _timeout );

  // See the comment for cstring_bounded_output for why we omit _read_str when we call this.
  int read_from_adu( libusb_device_handle * _device_handle, char * _read_str, int _read_str_len, int _timeout );
%}

// See the SWIG documentation for cstring.i. Declaring _read_str here
// means that we can't send a char* argument to read_from_adu even
// though it appears in the prototype.  So we skip that argument, and
// the function returns the string (as a string) anyway -- along with
// the normal return value.  The string will be the second element in
// a Tcl list.
%cstring_bounded_output(char * _read_str, 1024);

// Perform libusb initialization when the module is loaded
%init %{
  initialize();
%}

// Initialize libusb
int initialize();

libusb_device_handle * open_device(int vid, int pid);

int write_to_adu( libusb_device_handle * device_handle, const char * _cmd, int _timeout );
int read_from_adu( libusb_device_handle * _device_handle, char * _read_str, int _read_str_len, int _timeout );

