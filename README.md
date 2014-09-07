# What this is

There is a wonderful HOWTO on [setting up simh/vax with 4.3BSD-Quasijarus](http://gunkies.org/wiki/Installing_4.3_BSD_Quasijarus_on_SIMH)

In honour of that HOWTO, I have checked in some of the files that it references inline,
and made certain small adjustments with the goal of having networking operational
to a Linux host.

I have also adapted the script in the [simh Ethernet readme](https://github.com/simh/simh/blob/v3.9-0/0readme_ethernet.txt)
to work with the version of ifconfig and route that is on my Linux system.
it is checked in here as "bridge-setup.sh".

## Package prerequisites

These are the Gentoo packages I used:

* libpcap (or libpcap-dev if you are using a Debian derivative)
* bridge-utils
* usermode-utilities (aka uml-utilities)

Note that bridging requires a kernel module be enabled: "802.1d Ethernet Bridging"

## simh

I started with [version 3.9](https://github.com/simh/simh/archive/v3.9-0.tar.gz)

Make sure libpcap is installed before you build it. 

You should see something like this:

```
$ make vax
lib paths are: /lib/ /usr/i686-pc-linux-gnu/lib/ /usr/lib/ /usr/lib/OpenCL/vendors/amd/ /usr/lib/gcc-lib/i686-pc-linux-gnu/3.3.6/ /usr/lib/gcc/i686-pc-linux-gnu/4.1.2/ /usr/lib/gcc/i686-pc-linux-gnu/4.3.4/ /usr/lib/gcc/i686-pc-linux-gnu/4.4.5/ /usr/lib/gcc/i686-pc-linux-gnu/4.6.3/ /usr/lib/gcc/i686-pc-linux-gnu/4.7.3/ /usr/lib/opengl/ati/lib/ /usr/lib/qca2/ /usr/lib/qt4/ /usr/local/lib/
using libm: /usr/lib//libm.so
using librt: /usr/lib//librt.so
using libpthread: /usr/lib//libpthread.so /usr/include/pthread.h
using libdl: /usr/lib//libdl.so /usr/include/dlfcn.h
using libpcap: /usr/include/pcap.h
***
*** vax Simulator being built with:
*** - compiler optimizations and no debugging support. GCC Version: 4.7.3.
*** - dynamic networking support using Linux provided libpcap components.
```

## Installing 4.3BSD Quasijarus

The HOWTO steps are golden.

You _will_ need gzcompat, as the .Z format distributed is not compatible with Unix compress.

I obtained it like this:

```
  $  wget ftp://ifctfvax.harhan.org/pub/UNIX/components/compress.tar
  $  mkdir compress
  $  tar -C compress -xf compress.tar 
  $  cc -O2 compress/ucb/compress/gzcompat.c -o gzcompat
```

Then, in the 4.3BSD-Quasijarus0c directory, you can extract the archive files as follows:

```
  $ for Z in *.Z; do ./gzcompat < $Z | gzip -dc > ${Z%*.Z}; echo Done: $Z; done
```

Then carry on with the HOWTO steps from "The tape needs to be created with..."

The mkdisttap.pl program is checked in here, along with install.ini and boot.ini.

Once you have achieved the multi-user boot, you are ready to set up networking.

First, shut down BSD (`halt`). Exit simh (q). Then I recommend making a backup copy of the freshly installed disk image (quas.dsk). 

## Networking simh

To bridge simh to your (non-wireless) LAN on Linux, you can use the bridge-setup.sh script.

```
$ sudo ./bridge-setup.sh toby
```

The boot.ini script will attach the qe device to the bridged tap0 interface.

## Network setup in 4.3BSD

These steps are just the standard network interface setup. If you are using a different
guest operating system, just substitute the appropriate network setup steps.

First boot 4.3BSD:

```
$ ../simh-3.9-0/BIN/vax boot.ini 

VAX simulator V3.9-0
libpcap version 1.5.3
Eth: opened OS device tap0
...
4.3 BSD Quasijarus UNIX #3: Sat Feb 14 20:31:03 PST 2004
    root@luthien.Harhan.ORG:/nbsd/usr/src/sys/GENERIC
...
qe0 at uba0 csr 174440 vec 764, ipl 14
qe0: delqa, hardware address 08:00:2b:aa:bb:cc
...
4.3 BSD UNIX (quasijarus-simh) (console)

login: 

```

### Define netmask

The networks defined in /etc/networks are specific to UCB many years ago. We don't need them.
Set your correct netmask below:

```
# echo my-netmask 255.255.255 > /etc/networks
```

### Define hostname

Edit /etc/hosts and add a line for this host. Use the correct subnet (it will be the subnet
used by the bridge interface) and choose an unused IP address on this subnet.
You can also set the right address for localhost.

```
127.0.0.1     localhost 
192.168.2.198 quasijarus-simh
```

### Define interface

Edit /etc/netstart.
* Remove interfaces other than qe0
* Set the hostname 

My netstart file looks like:

```
#!/bin/sh -
#
#       @(#)netstart    1.1 (Berkeley) 1/10/99

routedflags=-q
rwhod=NO

# myname is my symbolic name
# my-netmask is specified in /etc/networks
#
hostname=quasijarus-simh
hostname $hostname

ifconfig qe0 inet $hostname netmask my-netmask

ifconfig lo0  inet localhost
route add $hostname localhost 0
hostid $hostname

```

## Test

Boot 4.3BSD.

From another host, telnet to the IP address you assigned (in netstart):

```
$ telnet 192.168.2.198
Trying 192.168.2.198...
Connected to 192.168.2.198.
Escape character is '^]'.


4.3 BSD UNIX (quasijarus-simh) (ttyp0)

login: 

```

## Gotchas

telnetd, ftpd and other network daemons are already installed and running in the default install.

Clients will not be able to telnet in until you have created pty devices:

```
# cd /dev
# MAKEDEV pty0 pty1
```

