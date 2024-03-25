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
    - [Command reference](#command-reference)
        - [High level commands](#high-level-commands)
            - [serial_number_list](#serial_number_list)
                - [Arguments](#arguments)
                - [Example](#example)

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

## Command reference ##

### High level commands ###

#### serial_number_list ####

Returns a list of connected ADU100 devices.  This calls
`tcladu::discovered_devices` internally to populate the connected
device database.

##### Arguments #####

None

##### Example #####

```
% package require tcladu
1.1.0
% tcladu::serial_number_list
B02597 B02797
```
