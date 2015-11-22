# OpenWRT-USB-Tethering
When using USB tethering with iOS, the folder who UUID.plist are stored (/var/lib/lockdown) is erased at each reboot...
So I've created the script "lockdown.sh" to backup those files each minute and restore it at each boot.

I've also managed to fit all necessary on a 4MB size firmware with LuCI.
It is based on the last OpenWRT 15.05 Chaos Calmer and all is pre-configured.

Included firmware for most popular routeur: TL-MR3020 and TL-W703N
(aks for any model supported by OpenWRT)

### How to

1. Download and install the firmware

2. After many tests, the best way to connect an iPhone is:
a. Inactive Internet sharing
b. Connect iPhone via USB
c. At asked, "Trust" the device
d. Active internet sharing
e. The blue band will appears on the top of the screen
    (if not after 30sec, inactive and reactive internet sharing)
f. Leave all connected at least one minute so the script can do its job

3. To test if the file has been created, disconnect and reconnect the iPhone.
If the dialog "Trust" appears, validate and repeat step 2.
When the connection is automatic, you're gone.

At each reboot, the internet sharing will be automatically activated even with locked screen :-)
A log is stored in /etc/lockdown/lockdown.log
