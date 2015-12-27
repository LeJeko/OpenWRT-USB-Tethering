#!/bin/sh

############################################################################
############################################################################
####																	####
####	LOCKDOWN v5														####
####																	####
####	An OpenWrt script to add USB Tethering for iOS and Android		####
####																	####
############################################################################
############################################################################

# v5 2015.12.27 : Jeko

# Features:
#
# Check the required packages and installs them if there is enough space available
# Up to 1.6 MB for all packages. A device with 8 MB flash is recommended.
# For the common TL-MR3020 and TL-W703N with 4MB flash, a customized firmware
# (without IPv6 and Wi-Fi support)
# is available at https://github.com/LeJeko/OpenWRT-USB-Tethering/releases
#
# Configure network and firewall via uci commands to ensure compatibility with all devices.
#
# Because of the folder /var/lib/lockdown is erased at each reboot,
# backup and restore UUID files stored in it. At boot then each minute.
#
# Check integrity of UUID files in case of a device was restored.

# Benefits:
# - For iOS, Internet sharing is automatically activated when you plug the USB cable
#   even if the screen is locked.
# - Device is charging.

# Installation:

# /!\ A valid internet connection via Wi-Fi or WAN Ethernet
# /!\ is required for installing required packages
# 1. copy the script on the device via scp
#    $ scp lockdown.sh root@192.168.1.1:/tmp/
# 2. connect to the device and install:
#	 $ sh /tmp/lockdown.sh install
# 3. Restart the device
# 4. Reconnect with new IP 192.1680.254

# Connect iOS device

# After many tests, the best way to connect an iPhone is:
# a. Inactive Internet sharing
# b. Connect iPhone via USB
# c. At asked, "Trust" the device
# d. Active internet sharing
# e. The blue band will appears on the top of the screen
#    (if not after 30sec, inactive and reactive internet sharing)
# f. Leave all connected at least one minute so the script can do its job
#
# To test if the file has been created, disconnect and reconnect the iPhone.
# If the dialog "Trust" appears, validate and repeat step 2.
# When the connection is automatic, you're gone.
# 
# A log is stored in /etc/lockdown/lockdown.log

############################################################################
####	BEGIN OF SCRIPT
############################################################################

# argument (source executing script)
if [ -z $1 ];then
	source="manual"
else
	source=$1
fi

# Lockdown log path
LOG="/etc/lockdown/lockdown.log"
path=`dirname "$0"`

################################
### installation start

if [ "$source" == "install" ];then

# Creating directories for log file
	if [ ! -d "/etc/lockdown/locks" ];then
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Creating lockdown directories"
		mkdir -p /etc/lockdown/locks
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Creating lockdown directories" >> $LOG
	fi

# checking modules
	packages="usbmuxd:830 libusbmuxd-utils:640 libimobiledevice-utils:100 kmod-usb-net-ipheth:40"
	install_pkg=""
	install_size=0

	for i in $packages;
	do
		pkg=`echo $i | awk -F":" '{print $1}'`
		size=`echo $i | awk -F":" '{print $NF}'`
		if [ -z `opkg list-installed | grep -E "^$pkg"` ];then
			install_pkg="$install_pkg $pkg"
			install_size=`expr $install_size + $size`
		fi
	done

	if [ "$install_pkg" != "" ];then
	# Checking free space
		FreeSpace=`df | grep rootfs | awk -F" " '{print $4}'`
		if [ "$FreeSpace" -lt "$install_size" ];then
			echo "====================================="
			echo "/!\ No more space to install packages"
			echo "Needed:    $install_size Ko"
			echo "Available: $FreeSpace Ko"
			echo "====================================="
			exit 0
		else
			echo "Space needed: $install_size Ko"
			echo "Free space: $FreeSpace Ko"
	# Check Internet connection
			if [ -z `ping -c 4 -w 5 8.8.8.8 | grep -e 'round-trip' | awk -F'/' '{print $4}'`];then
				echo "====================================="
				echo "/!\ Internet isn't available"
				echo "Can't install needed packages"
				echo "====================================="
				exit 0
			fi
	# installing packages
			echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Updating package list"
			echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Updating package list" >> $LOG
				opkg update
			echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Installing packages"
			echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Installing packages" >> $LOG
				opkg install $install_pkg
		fi
	else
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : No pkg install needed"
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : No pkg install needed" >> $LOG
	fi
	echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Installing script in /etc/lockdown/lockdown.sh"
	echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Installing script in /etc/lockdown/lockdown.sh" >> $LOG
	if [ ! -f "/etc/lockdown/lockdown.sh" ];then
		touch /etc/lockdown/locks/0000000000000000000000000000000000000000.plist
		cp $path/lockdown.sh /etc/lockdown/
		chmod +x /etc/lockdown/lockdown.sh
	fi
fi

### Installation end
################################

################################
### Verifying installation start

if [ ! -f "/etc/lockdown/lockdown.sh" ];then
	echo "====================================="
	echo "Lockdown isn't correctly installed"
	echo 'Please type: "sh lockdown.sh install"'
	echo "Quitting..."
	echo "====================================="
	exit 0
else
	################################
	### Checking configuration start

	if [ ! -f "/etc/lockdown/config.ok" ];then
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : checking configuration"
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : checking configuration" >> $LOG
		check=0

		### Check boot file
		if [ -z `cat /etc/init.d/boot | grep "lockdown"` ];then
			echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : configuring /etc/init.d/boot"
			echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : configuring /etc/init.d/boot" >> $LOG
			sed -i 25i'	echo "LOCKDOWN [$$] : -boot- : create /var/lib/lockdown" >> "/etc/lockdown/lockdown.log"' /etc/init.d/boot
			sed -i 25i'	mkdir -p /var/lib/lockdown' /etc/init.d/boot
			check=$((check + 1))
		else
			check=$((check + 1))
		fi
	fi

	### Configuring network and firewall
	if [ -z `cat /etc/config/network | grep "eth1"` ];then
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : configuring network and firewall"
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : configuring network and firewall" >> $LOG

	# network
		uci set network.usb=interface
		uci set network.usb.ifname='eth1 usb0'
		uci set network.usb.type=bridge
		uci set network.usb.proto=dhcp

	# firewall
		wan_network=`uci get firewall.@zone[1].network`
		uci set firewall.@zone[1].network="$wan_network usb"

	### commit at the end of the script

		check=$((check + 1))
	else
		check=$((check + 1))
	fi
	need_reboot=""
	if [ `uci get network.lan.ipaddr` != "192.168.0.254" ];then
		need_reboot="yes"
		check=$((check + 1))
	else
		check=$((check + 1))
	fi

	### Check rc.local configuration
	if [ -z `cat /etc/rc.local | grep "lockdown"` ];then
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : configuring /etc/rc.local"
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : configuring /etc/rc.local" >> $LOG
		sed -i 3i'sh /etc/lockdown/lockdown.sh "rc.local"' /etc/rc.local
		check=$((check + 1))
	else
		check=$((check + 1))
	fi

	### Check Cron configuration
	if [ ! -f "/etc/crontabs/root" ];then
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : create /etc/crontabs/root"
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : create /etc/crontabs/root" >> $LOG
		touch /etc/crontabs/root
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : configuring /etc/crontabs/root"
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : configuring /etc/crontabs/root" >> $LOG
		echo "* * * * * sh /etc/lockdown/lockdown.sh cron" >> /etc/crontabs/root
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : restarting cron"
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : restarting cron" >> $LOG
		/etc/init.d/cron restart                                                          
		check=$((check + 1))
	else
		check=$((check + 1))
	fi
	### Check counter
	if [ "$check" -eq 5 ];then
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Configuration OK"
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Configuration OK" >> $LOG
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Configuration OK" >> /etc/lockdown/config.ok
		rm -f /etc/lockdown/config.error
	else
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Configuration Error"
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Configuration Error" >> $LOG
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Configuration Error" >> /etc/lockdown/config.error
		rm -f /etc/lockdown/config.ok
	fi
	### Checking configuration end
	################################
fi
### Verifying installation end
################################

################################
### Restore start

if [ ! -d "/var/lib/lockdown" ];then
	echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Creating directory /var/lib/lockdown"
	echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : Creating directory /var/lib/lockdown" >> $LOG
	mkdir -p /var/lib/lockdown
fi

bkp_files=`ls /etc/lockdown/locks`
for file in $bkp_files;
do
	if [ ! -f "/var/lib/lockdown/$file" ];then
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : restore lockdown : $file"
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : restore lockdown : $file" >> $LOG
		cp /etc/lockdown/locks/$file /var/lib/lockdown/
	fi
done

### Restore end
################################

################################
### Backup start

for file in `ls /var/lib/lockdown | grep -v SystemConfiguration.plist`;
	do
	if [ ! -f "/etc/lockdown/locks/$file" ];then
		DeviceName=`ideviceinfo | grep DeviceName | awk -F":" '{print $NF}'`
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : backup lockdown for$DeviceName : $file"
		echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : backup lockdown for$DeviceName : $file" >> $LOG
		cp /var/lib/lockdown/$file /etc/lockdown/locks/
	else
# Case if Device was restored
		new_md5=`md5sum /var/lib/lockdown/$file | awk -F" " '{print $1}'`
		old_md5=`md5sum /etc/lockdown/locks/$file | awk -F" " '{print $1}'`
		if [ "$new_md5" != "$old_md5" ];then
			DeviceName=`ideviceinfo | grep DeviceName | awk -F":" '{print $NF}'`
			echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : updating lockdown for$DeviceName : $file"
			echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : updating lockdown for$DeviceName : $file" >> $LOG
			cp /var/lib/lockdown/$file /etc/lockdown/locks/
		fi
	fi
done

### Backup end
################################

###################################
### Verifying usbmudx porcess start

proc_usbmuxd=`ps | grep usbmuxd`

# In case of directly: nb_usbmuxd=`ps | grep usbmuxd| grep /usr/sbin/usbmuxd | wc -l`
# it result "grep" associated to command doesn't appears in ps output each 5 minutes !
# separate pipe ensure correct evaluation

nb_usbmuxd=`echo "$proc_usbmuxd" | grep /usr/sbin/usbmuxd | wc -l`
# echo "nb_usbmuxd: $nb_usbmuxd" >> $LOG
if [ ! "$nb_usbmuxd" -eq 1 ];then
	echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : starting usbmuxd"
	echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : starting usbmuxd" >> $LOG
	/usr/sbin/usbmuxd
fi

### Verifying usbmudx porcess end
###################################


###################################
### Final configuration and commit

if [ "$need_reboot" == "yes" ];then
	echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : changing LAN IP to 192.168.0.254"
	echo "LOCKDOWN [$$] : `date +\"%d.%m.%Y %T\"` : -$source- : changing LAN IP to 192.168.0.254" >> $LOG
	uci set network.lan.ipaddr='192.168.0.254'
	uci commit
	echo "========================================================================"
	echo "==================== NETWORK CONFIG HAS CHANGED ========================"
	echo "========================================================================"
	echo "/!\\--- Please type reboot and reconnect with new IP 192.168.0.254 ---/!\\"
	echo "========================================================================"
	echo "========================================================================"
	echo "/!\\--- Please type reboot and reconnect with new IP 192.168.0.254 ---/!\\" >> $LOG
fi
### Final configuration and commit
###################################

exit 0
