while true; do
    process="$(pgrep ddns-go)"
    if [ -z "$process" ]; then
        $MODDIR/bin/ddns-go -l 127.0.0.1:9876 -dns 223.5.5.5 -c $MODDIR/config/ddns_go_config.yaml
    fi
    sleep 3
done
