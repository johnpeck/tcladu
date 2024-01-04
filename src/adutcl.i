// SWIG interface definition


%module adutcl

%include cstring.i

%{
  // Put header files here or function declarations like below
  #include <libusb-1.0/libusb.h>
  int initialize();
  libusb_device_handle *  open_device(int vid, int pid);
  int write_to_adu( libusb_device_handle * device_handle, const char * _cmd, int _timeout );
  int read_from_adu( libusb_device_handle * _device_handle, char * _read_str, int _read_str_len, int _timeout );
%}

%cstring_bounded_output(char * _read_str, 1024);

// Perform initialization when the module is loaded
%init %{
  initialize();
%}



int initialize();
libusb_device_handle * open_device(int vid, int pid);

int write_to_adu( libusb_device_handle * device_handle, const char * _cmd, int _timeout );
int read_from_adu( libusb_device_handle * _device_handle, char * _read_str, int _read_str_len, int _timeout );

