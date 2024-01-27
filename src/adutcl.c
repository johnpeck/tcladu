
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>

// libusb library must be available. It can be installed on
// Debian/Ubuntu using apt-get install libusb-1.0-0-dev
#include <libusb-1.0/libusb.h>

#include "adutcl.h"

// ADU100 is a low-speed device, so we must use 8 byte transfers
#define TRANSFER_SIZE 8

adu100_t adu100s[10];

int found_adu100s = 0;

int initialize() {
  // We need to initialize libusb before we can use it.
  return libusb_init(NULL);
}

// Per the SWIG documentation:
//
// All pointers are treated as opaque objects by SWIG. Thus, a pointer
// may be returned by a function and passed around to other C
// functions as needed.
//
// So it's not strange that the device handle isn't declared globally.
libusb_device_handle * open_device(int vid, int pid) {
  int result;

  // Our ADU's USB device handle
  struct libusb_device_handle * device_handle = NULL;

  // Set debugging output to max level
  libusb_set_option( NULL, LIBUSB_OPTION_LOG_LEVEL, LIBUSB_LOG_LEVEL_WARNING );

  // Open the ADU device that matches our vendor id and product id
  device_handle = libusb_open_device_with_vid_pid( NULL, vid, pid );
  if ( !device_handle ) {
    printf( "Error finding USB device\n" );
    libusb_exit( NULL );
    exit( -2 );
  }

  // Enable auto-detaching of the kernel driver.
  // If a kernel driver currently has an interface claimed, it will be automatically be detached
  // when we claim that interface. When the interface is restored, the kernel driver is allowed
  // to be re-attached. This can alternatively be manually done via libusb_detach_kernel_driver().
  libusb_set_auto_detach_kernel_driver( device_handle, 1 );

  // Claim interface 0 on the device
  result = libusb_claim_interface( device_handle, 0 );
  if ( result < 0 ) {
    printf( "Error claiming interface: %s\n", libusb_error_name( result ) );
    if ( device_handle ) {
      libusb_close( device_handle );
    }
    libusb_exit( NULL );
    exit( -3 );
  }
  return device_handle;
}

// Read a command from an ADU device with a specified timeout
int read_from_adu( libusb_device_handle * _device_handle, char * _read_str, int _read_str_len, int _timeout ) {
  if ( _read_str == NULL || _read_str_len < 8 ) {
    return -2;
  }

  int bytes_read = 0;

  // Buffer to hold the command we will receive from the ADU device
  // Its size is set to the transfer size for low or full speed USB devices (ADU model specific - see defines at top of file)
  unsigned char buffer[ TRANSFER_SIZE ];

  // Zero out buffer to pad with null values (command buffer needs
  // to be padded with 0s)
  memset( buffer, 0, TRANSFER_SIZE );

  // Attempt to read the result from the IN endpoint (0x81) with user specified timeout
  int result = libusb_interrupt_transfer( _device_handle, 0x81, buffer, TRANSFER_SIZE, &bytes_read, _timeout );
  printf( "Read result: %i, Bytes read: %u\n", result, bytes_read );

  if ( result < 0 ) {
    printf( "Error reading interrupt transfer: %s\n", libusb_error_name( result ) );
    return result;
  }

  // The buffer should now hold the data read from the ADU
  // device. The first byte will contain 0x01, the remaining bytes
  // are the returned value in string format. Let's copy the string
  // from the read buffer, starting at index 1, to our _read_str
  // buffer
  memcpy( _read_str, &buffer[1], 7 );
  _read_str[7] = '\0'; // null terminate the string
  // printf( "Read value as string: %s\n", _read_str );

  return result; // returns 0 on success, a negative number specifying the libusb error otherwise
}

// Write a command to an ADU device with a specified timeout
int write_to_adu( libusb_device_handle * device_handle, const char * _cmd, int _timeout ) {
  // Get the length of the command string we are sending
  const int command_len = strlen( _cmd );

  int bytes_sent = 0;

  // Buffer to hold the command we will send to the ADU device.
  //
  // Its size is set to the transfer size for low or full speed USB
  // devices (ADU model specific - see defines at top of file)
  unsigned char buffer[ TRANSFER_SIZE ];

  if ( command_len > TRANSFER_SIZE ) {
    printf( "Error: command is larger than our limit of %i\n", TRANSFER_SIZE );
    return -1;
  }

  // Zero out buffer to pad with null values (command buffer needs to
  // be padded with 0s)
  memset( buffer, 0, TRANSFER_SIZE );

  // First byte of the command buffer needs to be set to a decimal
  // value of 1
  buffer[0] = 0x01;

  // Copy the command ASCII bytes into our buffer, starting at the
  // second byte (we need to leave the first byte as decimal value 1)
  memcpy( &buffer[1], _cmd, command_len );

  // Attempt to send the command to the OUT endpoint (0x01) with the
  // use specified millisecond timeout
  int result = libusb_interrupt_transfer( device_handle, 0x01, buffer, TRANSFER_SIZE, &bytes_sent, _timeout );
  printf( "Write '%s' result: %i, Bytes sent: %u\n", _cmd, result, bytes_sent );

  if ( result < 0 ) {
    printf( "Error sending interrupt transfer: %s\n", libusb_error_name( result ) );
  }

  return result; // Returns 0 on success, a negative number specifying the libusb error otherwise
}



int discovered_devices() {
  int found_adu100s = 0;
  int result = 0;

  // Get all devices on USB busses.  Make a list of libusb devices.
  libusb_device **devs;
  int found_devices;
  found_devices = libusb_get_device_list(NULL, &devs);
  // printf( "Found %u devices\n", found_devices);

  // Handles and descriptors to pass around
  struct libusb_device_handle * devh = NULL;
  struct libusb_device_descriptor desc;
  if (found_devices < 0) {
    libusb_exit(NULL);
    return -1;
  }

  // Temporarily carry the libusb output with unsigned char
  unsigned char libusb_string_descriptor[100];

  int found_adu100s_index = 0;
  for (int i = 0; i < found_devices; i++) {
    // Loop through all found USB devices
    result = libusb_get_device_descriptor(devs[i], &desc);
    if ( desc.idVendor == 0x0a07 && desc.idProduct == 0x0064 ) {
      // This is an Ontrak ADU100 device.  Open it to get the serial number.
      found_adu100s += 1;
      found_adu100s_index = found_adu100s - 1;

      // Populate members of the ADU100 database structure
      adu100s[found_adu100s_index].dev = devs[i];

      // Open the device to return a handle
      result = libusb_open(adu100s[found_adu100s_index].dev, \
			   &adu100s[found_adu100s_index].devh);

      // Use the handle to get the serial number
      result = libusb_get_string_descriptor_ascii(adu100s[found_adu100s_index].devh, \
						  desc.iSerialNumber, \
						  libusb_string_descriptor, \
						  sizeof(libusb_string_descriptor));
      strcpy(adu100s[found_adu100s_index].serial_string, (char *)libusb_string_descriptor);

      // Set the bus number
      adu100s[found_adu100s_index].bus_number = libusb_get_bus_number(adu100s[found_adu100s_index].dev);

      // Set the device number
      adu100s[found_adu100s_index].device_address = libusb_get_device_address(adu100s[found_adu100s_index].dev);

    }

  }
  libusb_close(devh);
  if (result == 0) {
    return found_adu100s;    
  }
  return found_adu100s;
}

void serial_number( int index, char * _read_str ) {
  //_read_str = adu100s[index].serial_string;
  // printf("%s\n", adu100s[index].serial_string);
  strcat(_read_str, adu100s[index].serial_string);
  return;
}

