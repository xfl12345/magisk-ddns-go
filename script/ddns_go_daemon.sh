while true; do
    process="$(pgrep ddns-go)"
    if [ -z "$process" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ddns-go process is not found. Starting.." >> "${EXTRA_LOG_SAVE_PATH}/ddns-go.log"
        $MODDIR/bin/ddns-go -l 127.0.0.1:9876 -dns 223.5.5.5 -c $MODDIR/config/ddns_go_config.yaml 2>&1 >> "${EXTRA_LOG_SAVE_PATH}/ddns-go.log"
        if [ -z "$process" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ddns-go was failed to run. Please take a look of the log file [${EXTRA_LOG_SAVE_PATH}/ddns-go.log]." >> "${EXTRA_LOG_SAVE_PATH}/ddns-go.log"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ddns-go started." >> "${EXTRA_LOG_SAVE_PATH}/ddns-go.log"
        fi
    fi
    sleep 3
done
