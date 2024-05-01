while true; do
    process="$(pgrep ddns-go)"
    if [ -z "$process" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ddns-go process is not found. Starting.." >> "${EXTRA_LOG_SAVE_PATH}/ddns-go.log"
        tmp_var="$MODDIR/bin/ddns-go -l 127.0.0.1:9876 -dns 223.5.5.5 -c $DDNS_GO_CONFIG_FILE_PATH 2>&1 >> ${EXTRA_LOG_SAVE_PATH}/ddns-go.log"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $tmp_var"
        $tmp_var
        if [ -z "$process" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ddns-go was failed to run." >> "${EXTRA_LOG_SAVE_PATH}/ddns-go.log"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ddns-go started." >> "${EXTRA_LOG_SAVE_PATH}/ddns-go.log"
        fi
    fi
    sleep 3
done
