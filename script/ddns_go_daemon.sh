while true; do
    process="$(pgrep ddns-go)"
    if [ -z "$process" ]; then
        $MODDIR/bin/ddns-go -c $MODDIR/config/ddns_go_config.yaml
    fi
    sleep 3
done
