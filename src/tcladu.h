

// ADU100 is a low-speed device, so we must use 8 byte transfers
#define TRANSFER_SIZE 8

// Maximum number of ADU100 devices allowed
#define MAX_DEVICES 10

typedef struct adu100 {
  // Serial number
  char serial_string[100];

  // Device from device list
  libusb_device *dev;

  // Device handle
  libusb_device_handle *devh;

  // USB bus number
  int bus_number;

  // USB device address
  int device_address;
} adu100_t;

// Return the count of ADU100s found on any bus, or an error code
//
// This function may fail if there's a problem with libusb or
// permissions.  It will indicate failure with a negative return.
int discovered_devices (void);


// Return the serial number of the nth discovered device
//
// Arguments:
//
//   index -- 0 to (connected ADU100s - 1)
//   _read_str -- String to contain the output (not needed with SWIG)
void serial_number( int index, char * _read_str );

// Return the handle for the nth discovered device
//
// Arguments:
//
//   index -- 0 to (connected ADU100s - 1)
libusb_device_handle *handle( int index );


// Initialize the ADU100 interface
//
// Arguments:
//
//   index -- 0 to (connected ADU100s -1)
int _initialize_device( int index );

// Write a command to an ADU100
//
// Arguments:
//
//   index -- 0 to (connected ADU100s -1)
//   command -- command to send
//   timeout_ms -- timeout passed to libusb_interrupt_transfer (ms)
int write_device( int index, const char *command, int timeout_ms);

// Read from an ADU100
//
// Arguments:
//
//   index -- 0 to (connected ADU100s -1)
//   _read_str -- Dummy argument handled by SWIG
//   chars_to_read -- Characters to read from the device
//   timeout_ms -- timeout passed to libusb_interrupt_transfer (ms)
int read_device( int index, char * _read_str, int chars_to_read, int timeout_ms );
