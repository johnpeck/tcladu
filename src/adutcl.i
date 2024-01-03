// SWIG interface definition
%module adutcl
%{
  // Put header files here or function declarations like below
  #include <libusb-1.0/libusb.h>
  int initialize();
  int open_device(int vid, int pid);
  int write_to_adu( const char * _cmd, int _timeout );
%}

int initialize();
int open_device(int vid, int pid);

int write_to_adu( const char * _cmd, int _timeout );
