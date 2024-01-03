// SWIG interface definition
%module adutcl
%{
  // Put header files here or function declarations like below
  #include <libusb-1.0/libusb.h>
  int initialize();
  libusb_device_handle *  open_device(int vid, int pid);
  int write_to_adu( libusb_device_handle * device_handle, const char * _cmd, int _timeout );
%}

int initialize();
libusb_device_handle * open_device(int vid, int pid);

int write_to_adu( libusb_device_handle * device_handle, const char * _cmd, int _timeout );
