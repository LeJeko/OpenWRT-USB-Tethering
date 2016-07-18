LOCKDOWN v5
===========
An OpenWrt script to add USB Tethering for iOS and Android
-----------
Why Lockdown ?
--------------
When using USB tethering with iOS, the folder who UUID.plist are stored (/var/lib/lockdown) is erased at each reboot...
So I've created the script "lockdown.sh" to backup those files each minute and restore it at each boot.

Custom firmwares for 4MB flash devices
----------------
Because of space needed for all packages,
I've also managed to fit all necessary on a 4MB size firmware with LuCI.
It is based on the last OpenWRT 15.05 Chaos Calmer and all is pre-configured.
This firmware doesn't support IPv6 and Wi-Fi.

Firmwares for most popular routeur TL-MR3020 and TL-W703N are provided in the releases
(aks for any model supported by OpenWRT)

Compile yourself
-------------
Rename the chaos_calmer.config file to .config to get the right menuconfig.

v5.1 2015.12.29 : Jeko
------------------
Features:

Check the required packages and installs them if there is enough space available
Up to 1.6 MB for all packages. A device with 8 MB flash is recommended.
For the common TL-MR3020 and TL-W703N with 4MB flash, a customized firmware
(without IPv6 and Wi-Fi support)
is available at https://github.com/LeJeko/OpenWRT-USB-Tethering/releases/tag/v5.1

Configure network and firewall via uci commands to ensure compatibility with all devices.

Because of the folder /var/lib/lockdown is erased at each reboot,
backup and restore UUID files stored in it. At boot then each minute.

Check integrity of UUID files in case of a device was restored.

Benefits:
- For iOS, Internet sharing is automatically activated when you plug the USB cable
  even if the screen is locked.
- Device is charging.

Installation:

* /!\ A valid internet connection via Wi-Fi or WAN Ethernet is required for installing required packages
* 1. copy the script on the device via scp
* $ scp lockdown.sh root@192.168.1.1:/tmp/
* 2. connect to the device and install:
* $ sh /tmp/lockdown.sh install
* 3. Restart the device
* 4. Reconnect with new IP 192.1680.254

Connect iOS device

After many tests, the best way to connect an iPhone is:
* a. Inactive Internet sharing
* b. Connect iPhone via USB
* c. At asked, "Trust" the device
* d. Active internet sharing
* e. The blue band will appears on the top of the screen
* (if not after 30sec, inactive and reactive internet sharing)
* f. Leave all connected at least one minute so the script can do its job

To test if the file has been created, disconnect and reconnect the iPhone.
If the dialog "Trust" appears, validate and repeat step 2.
When the connection is automatic, you're gone.

A log is stored in /etc/lockdown/lockdown.log
