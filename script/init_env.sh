#!/system/bin/sh

# 使用 BusyBox 接管常用程序
# alias_list="$($BUSYBOX --list | $BUSYBOX grep -v '\[')"
# for item in $alias_list; do
#     # echo "${item}"
#     alias $item="$BUSYBOX $item"
# done

# busybox的路径地址
BUSYBOX_SEARCH_PATH="$(magisk --path)/.magisk/busybox/busybox:/data/adb/ksu/bin/busybox"
BUSYBOX_PARENT_PATH=""
BUSYBOX_PATH=""

for the_path in $(echo "$BUSYBOX_SEARCH_PATH" | tr ":" "\n"); do
    if [ -f "$the_path" ]; then
        BUSYBOX_PATH="$the_path"
        BUSYBOX_PARENT_PATH=$(echo $the_path | sed 's#\/busybox$##g')
        break
    fi
done

if [[ x"$ARCH" == "x" ]]; then
    ARCH="$(cat $MODDIR/text/the_arch)"
fi

DDNS_GO_CONFIG_OLD_SAVE_PATH="/data/adb/modules/ddns_go/config"
DDNS_GO_CONFIG_SAVE_PATH="/data/adb/ddns_go/config"
DDNS_GO_CONFIG_FILE_PATH="$DDNS_GO_CONFIG_SAVE_PATH/ddns_go_config.yaml"
mkdir -p $DDNS_GO_CONFIG_SAVE_PATH

EXTRA_SAVE_PATH=/sdcard/Download/ddnsgo
EXTRA_BIN_SAVE_PATH="$EXTRA_SAVE_PATH/bin"
EXTRA_LOG_SAVE_PATH="$EXTRA_SAVE_PATH/log"
mkdir -p $EXTRA_BIN_SAVE_PATH
mkdir -p $EXTRA_LOG_SAVE_PATH

export PATH="$MODDIR/bin:$EXTRA_BIN_SAVE_PATH:/data/data/com.termux/files/usr/bin:$BUSYBOX_PARENT_PATH:$PATH"
