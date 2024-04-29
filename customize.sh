#!/system/bin/sh

if [ "$BOOTMODE" != true ]; then
  ui_print "! Please install in Magisk Manager"
  ui_print "! Install from recovery is NOT supported"
  abort "-----------------------------------------------------------"
fi

echo "$ARCH" > $MODPATH/text/the_arch
chmod 755 -R $MODPATH/script/
# . $MODPATH/script/use_busybox.sh
# ui_print "before  $(export -p)"
# export -p | awk '{if(NF>1) print $1"="$2}' | source /dev/stdin
# ui_print "after  $(export -p)"
. $MODPATH/script/ddns_go_update_util.sh

ui_print "- Detected architecture: $ARCH"
ui_print "- Checking Internet connection"
check_connectivity
if [[ "$RESULT_CHECK_CONNECTIVITY" == "ok" ]]; then
    update_geoip_and_cloudflare_info
    if [[ x"$GEOIP_LOCATION" != "x" ]]; then
        ui_print "Detected GEOIP location: [${GEOIP_LOCATION}]"
    else
        ui_print "Mission failed due to detect GEOIP location failed..."; abort;
    fi
else
    ui_print "It seem that you were not connected with Internet. Mission failed..."; abort;
fi

if [ -e /system/etc/resolv.conf ]; then
	ui_print "- File [/system/etc/resolv.conf] already exist. Merging..."
	cat $MODPATH/my_res/resolv.conf /system/etc/resolv.conf > /system/etc/resolv.conf
else
	ui_print "- File [/system/etc/resolv.conf] did not exist. Setting..."
	mkdir -p /system/etc
	cat $MODPATH/my_res/resolv.conf > /system/etc/resolv.conf
fi

ui_print "- Checking download tools"
if [[ x"CURL_PATH" == "x" ]]; then
    if [[ x"WGET_PATH" == "x" ]]; then
        ui_print "Neither [curl] or [wget] is available to use."
    else
        tmp_var=$(wget -O- https://www.qq.com/index.html 2>&1 | head -n 3 | grep -F "Connection reset by peer")
        if [[ x"$tmp_var" != "x" ]]; then
            ui_print "The tool [wget] is broken."
        else
            tmp_var="ok"
        fi
    fi

    if [[ "$tmp_var" != "ok" ]]; then
        ui_print "Please fix it by following solution:"
        ui_print "1. Install APP [Termux] from F-Droid [https://f-droid.org/en/packages/com.termux/]. Then install the curl by executing command [pkg install curl]."
        ui_print "2. Download curl binary file from [https://github.com/xfl12345/Cross-Compiled-Binaries-Android/tree/abadb8315e34f7bfa07b596e810617978f1b9984/curl] to [${EXTRA_BIN_SAVE_PATH}/curl] manually by yourself."
        ui_print "Here are some information for expert. Enviroment PATH=${PATH}"
        ui_print "Mission is failed. Exiting..."
        abort
    fi
fi

ui_print "- Checking neccessary dependence"
ui_install_binary() {
    ui_print "Download and install $1"
    case "$ARCH" in
        arm)
        ;;
        arm64)
        ;;
        x86)
        ;;
        x64)
        ;;
        *)
            ui_print "Mission failed due to no suitable $1 to download. CPU architecture is not supported."; abort;
        ;;
    esac
    RESULT_INSTALL_BINARY=""
    install_binary $1
    if [[ "$RESULT_INSTALL_BINARY" == "ok" ]]; then
        update_path_bin_function_name='update_path_bin_'$1
        $update_path_bin_function_name
    elif [[ "$RESULT_INSTALL_BINARY" == "mission_failed" ]]; then
        ui_print "Mission failed due to download $1 failed..."; abort;
    fi
}

if [[ x"$CURL_PATH" == "x" ]]; then
    ui_print "[curl] is not found"
    ui_install_binary curl
else
    ui_print "[${CURL_PATH}] is found"
fi

if [[ x"$JQ_PATH" == "x" ]]; then
    ui_print "[jq] is not found"
    ui_install_binary jq
else
    ui_print "[${JQ_PATH}] is found"
fi

ui_print "- Delete useless file"
rm $MODPATH/text/sha256*

ui_print "- Finding released build of [$ARCH] architecture"
update_latest_release_info
if [[ "$LATEST_RELEASE_TAG_NAME" == "arch_not_support" ]]; then
    ui_print "Mission failed due to no suitable ddns-go to download. CPU architecture is not supported."; abort;
fi

ui_print "- Downloading module files"
download_ddns_go_archive_file
if [ $? -ne 0 ]; then
    ui_print "Mission failed due to download failed. See the log file [${EXTRA_LOG_SAVE_PATH}/debug.log] for more details."
    abort
fi

ui_print "- Extracting module files"
extract_ddns_go_archive_file
if [ $? -ne 0 ]; then
    ui_print "Mission failed due to extract file failed. See the log file [$EXTRA_LOG_SAVE_PATH/debug.log] for more details."
    abort
fi

# export ARCH=$ARCH
# export MODPATH=$MODPATH
# ASH_STANDALONE=1 busybox sh -c "$MODPATH/service.sh" &
