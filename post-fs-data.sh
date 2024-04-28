#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}


# Edit the resolv conf file if it exist

chmod 755 -R $MODPATH/script/
. $MODDIR/script/init_env.sh

rm -r $MODDIR/system/
mkdir -p $MODDIR/system/etc/
cp $MODDIR/my_res/resolv.conf $MODDIR/system/etc/resolv.conf
if [ -e /system/etc/resolv.conf ]; then
	myTmpVar=$(cat $MODDIR/my_res/resolv.conf | awk '{print $2}')
	myResolvFileContent=$(cat /system/etc/resolv.conf)
	for the_dns_address in $myTmpVar; do
		myResolvFileContent=$(echo -e "$myResolvFileContent" | grep -v $the_dns_address)
	done
	echo -e "$myResolvFileContent" >> $MODDIR/system/etc/resolv.conf
fi
