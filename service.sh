#!/system/bin/sh

MODDIR="$(dirname "$(readlink -f "$0")")"

chmod 755 $MODDIR/bin/ddns-go

while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 5s
done

chmod 755 -R $MODDIR/script/

# ddns-go 守护进程
. "$MODDIR/script/init_env.sh"
export EXTRA_LOG_SAVE_PATH=$EXTRA_LOG_SAVE_PATH
ASH_STANDALONE=1 busybox sh -c "$MODDIR/script/ddns_go_daemon.sh" &

# 启动 ddns-go 自动更新服务
. $MODDIR/script/ddns_go_update_util.sh


while true; do
    delete_log
    check_connectivity
    if [[ "$RESULT_CHECK_CONNECTIVITY" != "ok" ]]; then
        sleep 5s
        continue
    fi
    check_and_update_version
    sleep 24h
done
