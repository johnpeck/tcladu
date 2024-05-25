# tcladu #

Tcl package supporting multiple [ADU100s](https://www.ontrak.net/ADU100.htm) from [Ontrak Control Systems](https://www.ontrak.net/index.html) via [libusb](https://libusb.info/) and [SWIG](https://www.swig.org/).

![ADU100 BW](img/bw_adu100.png)

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [tcladu](#tcladu)
    - [Demonstration](#demonstration)
        - [What did we just do?](#what-did-we-just-do)
            - [Unpacked the TGZ](#unpacked-the-tgz)
            - [Appended the package to Tcl's `auto_path`](#appended-the-package-to-tcls-auto_path)
            - [Required the package](#required-the-package)
            - [Populated the connected device database](#populated-the-connected-device-database)
            - [Queried the device database for device 0](#queried-the-device-database-for-device-0)
            - [Sent the command to set/close the ADU100's relay](#sent-the-command-to-setclose-the-adu100s-relay)
            - [Sent the command to read the relay status](#sent-the-command-to-read-the-relay-status)
            - [Read from the ADU100](#read-from-the-adu100)
            - [Sent the command to reset/open the ADU100's relay](#sent-the-command-to-resetopen-the-adu100s-relay)
            - [Sent the command to check the relay status again](#sent-the-command-to-check-the-relay-status-again)
            - [Read from the ADU100](#read-from-the-adu100-1)
    - [Getting started](#getting-started)
        - [Install libusb-1.0](#install-libusb-10)
        - [Install a udev rule](#install-a-udev-rule)
        - [Requiring the package](#requiring-the-package)
    - [Command reference](#command-reference)
        - [Low level commands](#low-level-commands)
            - [discovered_devices](#discovered_devices)
                - [Arguments](#arguments)
                - [Returns](#returns)
                - [Example](#example)
            - [_initialize_device](#_initialize_device)
                - [Arguments](#arguments-1)
                - [Returns](#returns-1)
                - [Example](#example-1)
            - [_read_device](#_read_device)
                - [Arguments](#arguments-2)
                - [Returns](#returns-2)
        - [High level commands](#high-level-commands)
            - [initialize_device](#initialize_device)
                - [Arguments](#arguments-3)
                - [Returns](#returns-3)
                - [Example](#example-2)
            - [serial_number_list](#serial_number_list)
                - [Arguments](#arguments-4)
                - [Returns](#returns-4)
                - [Example](#example-3)
            - [clear_queue](#clear_queue)
                - [Arguments](#arguments-5)
                - [Returns](#returns-5)
                - [Example](#example-4)
            - [send_command](#send_command)
                - [Arguments](#arguments-6)
                - [Returns](#returns-6)
                - [Example](#example-5)
            - [read_device](#read_device)
            - [query](#query)
                - [Arguments](#arguments-7)
                - [Example](#example-6)
    - [References](#references)

<!-- markdown-toc end -->

## Demonstration ##

Let's say you've downloaded a release binary from
[Sourceforge](https://tcladu.sourceforge.io), and you have a few (two)
ADU100s connected.  You also need permissions to access the device,
but let's say you have those.

<pre><code>
<b>johnpeck@darkstar:~/Downloads $</b> tar xzvf tcladu-1.0.0-linux-x64.tar.gz
tcladu/
tcladu/pkgIndex.tcl
tcladu/tcladu.so
<b>johnpeck@darkstar:~/Downloads $</b> cd ~
<b>johnpeck@darkstar:~ $</b> tclsh
<b>%</b> lappend auto_path ~/Downloads
/usr/share/tcltk/tcl8.6 /usr/share/tcltk ... ~/Downloads
<b>%</b> puts [package require tcladu]
1.0.0
<b>%</b> puts [tcladu::discovered_devices]
2
<b>%</b> puts [tcladu::serial_number 0]
B02597
<b>%</b> puts [tcladu::write_device 0 "SK0" 200]
0
<b>%</b> puts [tcladu::write_device 0 "RPK0" 200]
0
<b>%</b> puts [tcladu::read_device 0 8 200]
0 1
<b>%</b> puts [tcladu::write_device 0 "RK0" 200]
0
<b>%</b> puts [tcladu::write_device 0 "RPK0" 200]
0
<b>%</b> puts [tcladu::read_device 0 8 200]
0 0
</pre></code>

### What did we just do? ###

#### Unpacked the TGZ ####

The package is just two files: `pkgIndex.tcl`, used by Tcl's
[package](https://wiki.tcl-lang.org/page/package) procedure, and
`tcladu.so`, a binary produced from some `c` code.

#### Appended the package to Tcl's `auto_path` ####

The [auto_path](https://wiki.tcl-lang.org/page/auto_path) list tells Tcl where to look for packages.

#### Required the package ####

This both loads procedures into the `tcladu` namespace and initializes libusb.

#### Populated the connected device database ####

The `discovered_devices` command will populate a device database with
things like device handles and serial numbers.  This must be called
before writing to or reading from devices.

#### Queried the device database for device 0 ####

The `serial_number` command doesn't do anything with connected
hardware -- it just returns a serial number populated by
`discovered_devices`.

#### Sent the command to set/close the ADU100's relay ####

The `write_device` command takes a device index instead of some kind
of handle to identify the targeted device. It then takes an ASCII
command that you can find in the [ADU100
manual](https://www.ontrak.net/PDFs/adu100a.pdf) to manipulate the
hardware relay.  The last argument is a timeout for libusb (in
milliseconds), which will become more interesting when we get into
reading from the hardware.

#### Sent the command to read the relay status ####

Reading the relay status starts with telling the ADU100 to read the
status.  It will prepare the result to be read by the next libusb
read.  The return value for the `RPK0` command is just a success code
-- not the relay status.

#### Read from the ADU100 ####

The `read_device` command takes a device index, followed by the number
of bytes we want to read.  This payload size is a placeholder for now,
although it has to be 8 bytes or larger.  I want to keep it to handle
larger payloads on other Ontrak devices this might support in the
future.

The final argument is the familiar ms timeout.  Libusb will throw a
timeout error if the read takes longer than this value.  But this
error isn't fatal, and your code can catch this and simply try again.
This gives your application a chance to stay active while you wait for
a long hardware read.

The result is a Tcl [list](https://wiki.tcl-lang.org/page/list)
containing the success code and return value.  In this case, a `1`
shows us that the relay is set/closed.

#### Sent the command to reset/open the ADU100's relay ####

This is the opposite of the set command.

#### Sent the command to check the relay status again ####

We'll now expect the hardware to report 0 for the relay status.

#### Read from the ADU100 ####

The returned list is now `0 0`, telling us that the command succeeded
and that the relay is reset/open.

## Getting started ##

### Install libusb-1.0 ###

We need `libusb-1.0-0` to call the libusb functions in tcladu.  This
comes from Ubuntu's `libusb-1.0-0` package, and I'm using version
`2:1.0.25-1ubuntu2` on 2024-Mar-07.

We need `libusb-1.0/libusb.h` to build the package, which comes from
Ubuntu's `libusb-1.0-0-dev` package.  I have the same version of the
binary and dev packages.

### Install a udev rule ###

You can't communicate with the ADU100 without permission, and
[udev](https://en.wikipedia.org/wiki/Udev) allows configuring that
permission when devices are plugged in.  I copy the rule [here](/doc/10-ontrak.rules) to `/usr/lib/udev/rules.d` and then call

```
sudo udevadm control --reload-rules
```

...to activate the new rule.  Remember that these rules are only
applied to new devices, so you'll need to unplug and plug your device
after reloading the rules.  The rule I've linked is for any Ontrak
device, and it sets the device mode to `0666`.  You can use
[a nice permissions calculator](https://nettools.club/chmod_calc) to
set whatever permissions you need.

You can make sure permissions are working with `lsusb` from `usbutils`.

<pre><code>
<b>johnpeck@darkstar:~ $</b> lsusb | grep Ontrak
Bus 001 Device 017: ID 0a07:0064 Ontrak Control Systems Inc. ADU100 Data Acquisition Interface
</pre></code>

...which means the device is located at `/dev/bus/usb/001/017`.  We can check the permissions with

<pre><code>
<b>johnpeck@darkstar:~ $</b> ls -al /dev/bus/usb/001/017
crw-rw-rw- 1 root root 189, 16 Mar  2 05:44 /dev/bus/usb/001/017
</pre></code>

...showing that our rule is working.

### Requiring the package ###

Place the package somewhere the Tcl auto loader can find it.  I like
`usr/share/tcltk`.  This path must be in the `auto_path` list.  For
example,

```
% puts $auto_path
/usr/share/tcltk/tcllib1.20 ... /usr/share/tcltk ...
```

...my `auto_path` includes `/usr/share/tcltk`.  When I put **tcladu** in that directory, I can require it with

```
% package require tcladu
1.1.1
```

...where the command returns the loaded version.  I can then make sure
the package got loaded from the right place with

```
% package ifneeded tcladu 1.1.1
load /usr/share/tcltk/tcladu1.1.1/tcladu.so
source /usr/share/tcltk/tcladu1.1.1/tcladu.tcl
```

...showing the path I expected.  This step is more important if you
build the package yourself, as you might have intermediate builds
around with the same version number.  See the references below for
more information about **package ifneeded**.

## Command reference ##

### Low level commands ###

These are commands implemented in `tcladu.c` and broken out via
**SWIG**.

#### discovered_devices ####

This command returns the number of ADU100 devices discovered on USB.  The key line is

```
if ( desc.idVendor == 0x0a07 && desc.idProduct == 0x0064 ) {
```

...showing how
[USB descriptors](https://developerhelp.microchip.com/xwiki/bin/view/applications/usb/how-it-works/descriptors/)
are used to discover ADU100s.  This command also populates the device
database -- required for using numbers like the device index in other
commands.

##### Arguments #####

None

##### Returns #####

* 0 to the number of discovered ADU100 devices if successful
* -1 if there was an error during discovery

##### Example #####

We can get the number of connected ADU100s and populate the internal database with

```
% package require tcladu
1.1.1
% tcladu::discovered_devices
1
```

...where **tcladu** correctly found 1 connected ADU100.

#### _initialize_device ####

This command is more about initializing the USB interface than it is
about initializing the ADU100 hardware.  But it acts on one device
instead of some broader initialization.  It does two things:
1. Enable libusb's [automatic kernel driver detachment](https://libusb.sourceforge.io/api-1.0/group__libusb__dev.html#gac35b26fef01271eba65c60b2b3ce1cbf) for the chosen ADU100.
2. Claim interface number 0 for the chosen ADU100.  See the [libusb documentation](https://libusb.sourceforge.io/api-1.0/group__libusb__dev.html#gaee5076addf5de77c7962138397fd5b1a).

The device database must be populated with
`tcladu::serial_number_list` or `tcladu::discovered_devices` before
calling this function.

##### Arguments #####

1. Device index (0, 1, ..., connected ADU100s -1)

##### Returns #####

* 0 on success
* [libusb error code](https://libusb.sourceforge.io/api-1.0/group__libusb__misc.html#gab2323aa0f04bc22038e7e1740b2f29ef) on error

##### Example #####

```
% package require tcladu
1.1.3
% tcladu::serial_number_list
B02797
% tcladu::_initialize_device 0
0
```

#### _read_device ####

Read the device's response to a command.

##### Arguments #####

1. Device index (0, 1, ..., connected ADU100s -1)
2. Pointer to memory used for the returned string (handled by SWIG)
3. Characters to read
4. How long to tell libusb to wait for data (ms)

##### Returns #####

* On success, a list of
1. 0 to indicate success
2. The string read from the ADU100

Note that the returned string is handled by SWIG.  The only explicit
return is the integer returned by the C code.

* On error, a negative error code to be interpreted by [read_device](#read_device).

### High level commands ###

#### initialize_device ####

This command calls the low-level [_initialize_device](#_initialize_device), allowing
libusb errors to throw Tcl errors.

##### Arguments #####

1. Device index (0, 1, ..., connected ADU100s -1)

##### Returns #####

* 0 on success
* [Tcl error](https://www.tcl.tk/man/tcl/TclCmd/error.htm) on error

##### Example #####

The high-level `initialize_device` and low-level `_initialize_device` have the same usage.

```
% package require tcladu
1.1.3
% tcladu::serial_number_list
B02797
% tcladu::initialize_device 0
0
```

#### serial_number_list ####

Returns a list of connected ADU100 devices.  This calls
`tcladu::discovered_devices` internally to populate the connected
device database.

##### Arguments #####

None

##### Returns #####

A list of discovered ADU100 devices.  This list will be empty if no
devices are discovered.

##### Example #####

```
% package require tcladu
1.1.0
% tcladu::serial_number_list
B02597 B02797
```

#### clear_queue ####

Returns a list of `success code` `execution time` after repeatedly
calling **read_device()** to clear the ADU100's transmit buffer.  This
prevents confusion from queries returning old data.

##### Arguments #####

1. Device index (0, 1, ..., connected ADU100s -1)

##### Returns #####

* On success, a list of
1. 0 to indicate success
2. Elapsed time needed to clear the queue

* On failure, a [Tcl error](https://www.tcl-lang.org/man/tcl/TclCmd/error.htm)

##### Example #####

Clear the queue (of the ADU100 at index 0) with

```
% package require tcladu
1.1.1
% tcladu::serial_number_list
B02597
% tcladu::initialize_device 0
0
% tcladu::clear_queue 0
0 12
```

...and the return tells us this took 12ms to succeed.  We need to call
`initialize_device` here because `clear_queue` sends commands to the
device.

#### send_command ####

Returns a list of `success code` `execution time` after sending an
ASCII command.  You must call `serial_number_list` to populate the
device database before calling `send_command`.

##### Arguments #####

1. Device index (0, 1, ..., connected ADU100s -1)
2. Command

##### Returns #####

* On success, a list of
1. 0 to indicate success
2. Elapsed time needed to send the command (not to process the command)

##### Example #####

This sequence shows populating the device database, then setting (closing) the ADU100's relay.

```
% package require tcladu
1.1.0
% tcladu::serial_number_list
B02597 B02797
% tcladu::initialize_device 0
0
% tcladu::send_command 0 "SK0"
0 8
```

The return is `0` (success), followed by `8` -- it took 8ms to get a
response from the ADU100 (this is not how long it takes to close the
relay).

#### read_device ####

#### query ####

Returns a list of `success code` `response` `execution time` after
sending an ASCII query command.  You must call `serial_number_list` to populate the
device database before calling `query`.

##### Arguments #####

1. Device index (0, 1, ..., connected ADU100s -1)
2. Command

##### Example #####

This sequence shows querying the (open/reset) relay status, closing
the relay, then querying again.

```
% package require tcladu
1.1.1
% tcladu::serial_number_list
B02597
% tcladu::clear_queue 0
0 13
% tcladu::query 0 RPK0
0 0 10
% tcladu::send_command 0 SK0
0 5
% tcladu::query 0 RPK0
0 1 14
```

The final response of `1` shows that the relay is closed.

## References ##

1. See [the Tcler's Wiki](https://wiki.tcl-lang.org/page/package+ifneeded) for a description of **package ifneeded**.
2. See
   [the libusb 1.0 API documentation](https://libusb.sourceforge.io/api-1.0/libusb_api.html)
   for better descriptions of the low-level commands.
