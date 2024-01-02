/* File : example.c */

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>

// libusb library must be available. It can be installed on Debian/Ubuntu using apt-get install libusb-1.0-0-dev
#include <libusb-1.0/libusb.h>

static struct libusb_device_handle *devh = NULL;
int initialize() { return libusb_init(NULL); }

int open_device(int vid, int pid) {
  // Set debugging output to max level
  libusb_set_option( NULL, LIBUSB_OPTION_LOG_LEVEL, LIBUSB_LOG_LEVEL_WARNING );
  
  devh = libusb_open_device_with_vid_pid(NULL, vid, pid);
  if(!devh) return -1;
  return 0;
}

