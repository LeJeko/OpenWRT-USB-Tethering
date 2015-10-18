#!/bin/sh
#
# Patch for iPhone USB tethering lockdown
#
# v4.0 2015.10.17 : Jeko
# - add Android tethering
# v4.1 2015.10.18 : Jeko
# - add 'usb0' interface and bridge it with 'eth1'
# - change default ip to 192.168.0.254
# v4.2 2015.10.18 : Jeko
# - LuCI come back !
# - complete remove of IPv6 support
# v4.3 2015.10.18 : Jeko
# - add opkg
#
# Use:
# ./lockdown.sh install
# => installing script in /etc/lockdown

# argument (source executing script)
if [ -z $1 ];then
	source="manual"
else
	source=$1
fi

# Lockdown log path
LOG="/etc/lockdown/lockdown.log"

################################
### installation start

if [ "$source" == "install" ];then
	mkdir -p /etc/lockdown/locks
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : Creating lockdown directories"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : Creating lockdown directories" >> $LOG
	touch /etc/lockdown/locks/0000000000000000000000000000000000000000.plist
	cp lockdown.sh /etc/lockdown/
	chmod +x /etc/lockdown/lockdown.sh
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : Script /etc/lockdown/lockdown.sh installed"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : Script /etc/lockdown/lockdown.sh installed" >> $LOG
fi

### Installation end
################################

################################
### Verifying installation start

if [ ! -f /etc/lockdown/lockdown.sh ];then
		echo "-------------------------------------"
		echo "Lockdown isn't correctly installed"
		echo 'Please type: "sh lockdown.sh install"'
		echo "and run script from /etc/lockdown/"
		echo "Quitting..."
		echo "-------------------------------------"
		exit 0
fi

### Verifying installation end
################################

################################
### Checking configuration start

if [ ! -f /etc/lockdown/config.ok ];then
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : checking configuration"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : checking configuration" >> $LOG
	check=0

### Check boot file
if [ -z `cat /etc/init.d/boot | grep "lockdown"` ];then
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : configuring /etc/init.d/boot"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : configuring /etc/init.d/boot" >> $LOG
	sed -i 25i'	echo "LOCKDOWN [$$] : -boot- : create /var/lib/lockdown" >> "/etc/lockdown/lockdown.log"' /etc/init.d/boot
	sed -i 25i'	mkdir -p /var/lib/lockdown' /etc/init.d/boot
	check=$((check + 1))
else
	check=$((check + 1))
fi

### Check network configuration
if [ -z `cat /etc/config/network | grep "eth1"` ];then
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : configuring /etc/config/network"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : configuring /etc/config/network" >> $LOG
	echo "config interface wan" >> /etc/config/network
	echo "        option type 'bridge'" >> /etc/config/network
	echo "        option proto 'dhcp'" >> /etc/config/network
	echo "        option ifname 'eth1 usb0'" >> /etc/config/network
	echo "" >> /etc/config/network
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : restarting network"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : restarting network" >> $LOG
	/etc/init.d/network restart
	check=$((check + 1))
else
	check=$((check + 1))
fi
need_reboot=""
if [ -z `cat /etc/config/network | grep "192.168.0.254"` ];then
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : changing IP to 192.168.0.254"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : changing IP to 192.168.0.254" >> $LOG
	sed -i -e "s/192.168.1.1/192.168.0.254/g" /etc/config/network
	need_reboot="yes"
	check=$((check + 1))
else
	check=$((check + 1))
fi

### Check rc.local configuration
if [ -z `cat /etc/rc.local | grep "lockdown"` ];then
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : configuring /etc/rc.local"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : configuring /etc/rc.local" >> $LOG
	sed -i 3i'sh /etc/lockdown/lockdown.sh "rc.local"' /etc/rc.local
	check=$((check + 1))
else
	check=$((check + 1))
fi

### Check Cron configuration
if [ ! -f /etc/crontabs/root ];then
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : create /etc/crontabs/root"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : create /etc/crontabs/root" >> $LOG
	touch /etc/crontabs/root
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : configuring /etc/crontabs/root"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : configuring /etc/crontabs/root" >> $LOG
	echo "* * * * * sh /etc/lockdown/lockdown.sh cron" >> /etc/crontabs/root
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : restarting cron"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : restarting cron" >> $LOG
	/etc/init.d/cron restart                                                          
	check=$((check + 1))
else
	check=$((check + 1))
fi

if [ $check -eq 5 ];then
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : Configuration OK"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : Configuration OK" >> $LOG
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : Configuration OK" >> /etc/lockdown/config.ok
	rm -f /etc/lockdown/config.error
	else
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : Configuration Error"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : Configuration Error" >> $LOG
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : Configuration Error" >> /etc/lockdown/config.error
	rm -f /etc/lockdown/config.ok
fi

fi

### Checking configuration end
################################

################################
### Restore start

if [ ! -d /var/lib/lockdown ];then
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : Creating directory /var/lib/lockdown"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : Creating directory /var/lib/lockdown" >> $LOG
	mkdir -p /var/lib/lockdown
fi

bkp_files=`ls /etc/lockdown/locks`
for file in $bkp_files;
do
if [ ! -f /var/lib/lockdown/$file ];then
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : restore lockdown : $file"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : restore lockdown : $file" >> $LOG
	cp /etc/lockdown/locks/$file /var/lib/lockdown/
fi
done

### Restore end
################################

################################
### Backup start

nb_var_files=`ls /var/lib/lockdown | grep -v SystemConfiguration.plist | wc -l`
if [ ! "$nb_var_files" -eq 0 ];then
	var_files=`ls /var/lib/lockdown | grep -v SystemConfiguration.plist`
	for file in $var_files;
	do
	if [ ! -f /etc/lockdown/locks/$file ];then
		DeviceName=`ideviceinfo | grep DeviceName | awk -F":" '{print $NF}'`
		echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : backup lockdown for$DeviceName : $file"
		echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : backup lockdown for$DeviceName : $file" >> $LOG
		cp /var/lib/lockdown/$file /etc/lockdown/locks/
	else
# Case if Device was restored
		new_md5=`md5sum /var/lib/lockdown/$file | awk -F" " '{print $1}'`
		old_md5=`md5sum /etc/lockdown/locks/$file | awk -F" " '{print $1}'`
		if [ "$new_md5" != "$old_md5" ];then
			DeviceName=`ideviceinfo | grep DeviceName | awk -F":" '{print $NF}'`
			echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : updating lockdown for$DeviceName : $file"
			echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : updating lockdown for$DeviceName : $file" >> $LOG
			cp /var/lib/lockdown/$file /etc/lockdown/locks/
		fi
	fi
	done
fi

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
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : starting usbmuxd"
	echo "LOCKDOWN [$$] : `date +"%d.%m.%Y %T"` : -$source- : starting usbmuxd" >> $LOG
	/usr/sbin/usbmuxd
fi

### Verifying usbmudx porcess end
###################################

if [ "$need_reboot" = "yes" ];then
	echo "!!!--- Please type reboot and reconnect with new IP 192.168.0.254 ---!!!"
	echo "!!!--- Please type reboot and reconnect with new IP 192.168.0.254 ---!!!" >> $LOG
fi

exit 0