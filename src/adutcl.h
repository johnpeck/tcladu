

typedef struct adu100 {
  // Serial number
  unsigned char serial_string[100];

  // Device from device list
  libusb_device *dev;

  // Device handle
  libusb_device_handle *devh;

  // USB bus number
  int bus_number;

  // USB device address
  int device_address;
} adu100_t;
