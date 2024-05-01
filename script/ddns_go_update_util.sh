#!/system/bin/sh

# ui_print "${PATH}"
# ui_print "$(export)"
# ui_print "$(MODPATH)"

# 获取模块根目录
if [[ x"$MODDIR" == "x" ]]; then
    if [[ x"$MODPATH" == "x" ]]; then
        MODDIR="$(dirname \"$(readlink -f \"$0/../\")\")"
    else
        MODDIR=$MODPATH
    fi
fi

. $MODDIR/script/init_env.sh
CURL_PATH=""
WGET_PATH=""
JQ_PATH=""
# if [[ x"$(which curl)" != "x" -o x"$(busybox --list | grep curl)" != "x" ]]; then
update_path_bin_curl() {
    CURL_PATH="$(which curl)"
}
update_path_bin_wget() {
    WGET_PATH="$(which wget)"
}
update_path_bin_jq() {
    JQ_PATH="$(which jq)"
}
update_path_bin_curl
update_path_bin_wget
update_path_bin_jq

# 网络上的地理位置，将用于判断是否使用镜像源
GEOIP_LOCATION=""
LATEST_DOWNLOAD_URL=""
LATEST_DOWNLOAD_URL_FILENAME=""
LATEST_RELEASE_TAG_NAME=""
WORKED_CLOUDFLARE_CDN_NODE=""
RESULT_INSTALL_BINARY=""
RESULT_CHECK_SHA256SUM=""
RESULT_CHECK_CONNECTIVITY=""
# RESULT_EXTRACT_DDNS_GO_ARCHIVE_FILE=""

get_log_date() {
    echo "$(date '+%Y-%m-%d %H:%M:%S')"
}

get_github_resource_download_url() {
    case "$2" in
        CN)
            echo "https://gh.con.sh/$1"
        ;;
        *)
            echo "$1"
        ;;
    esac
}

check_sha256sum() {
    RESULT_CHECK_SHA256SUM="bad"
    result_sha256sum=$(sha256sum $MODDIR/tmp/$1 | awk '{print $1}')
    origin_sha256sum=$(cat $MODDIR/text/sha256_$1.txt | grep "$1\-$ARCH$" | awk '{print $1}')
    # echo "sha256sum $MODDIR/tmp/$1 --> $result_sha256sum" >> $EXTRA_LOG_SAVE_PATH/debug.log
    # echo "cat $MODDIR/text/sha256_$1.txt --> $origin_sha256sum" >> $EXTRA_LOG_SAVE_PATH/debug.log
    if [[ "$result_sha256sum" == "$origin_sha256sum" ]]; then
        RESULT_CHECK_SHA256SUM="ok"
    fi
    # echo "RESULT_CHECK_SHA256SUM=$RESULT_CHECK_SHA256SUM" >> $EXTRA_LOG_SAVE_PATH/debug.log
}

install_binary() {
    RESULT_INSTALL_BINARY="mission_failed"
    download_url=$(get_github_resource_download_url "https://github.com/xfl12345/Cross-Compiled-Binaries-Android/raw/abadb8315e34f7bfa07b596e810617978f1b9984/$1/$1-$ARCH" $GEOIP_LOCATION)
    mkdir -p "${MODDIR}/tmp"
    download_save_path="${MODDIR}/tmp/$1"
    if [[ x"$CURL_PATH" != "x" ]]; then
        download_tool_cmd="curl --silent --parallel --location --output"
    else
        download_tool_cmd="wget -q -O"
    fi
    download_tool_cmd="$download_tool_cmd $download_save_path $download_url"
    # 允许再多重新下载 2 次
    for item in 1 2 3; do
        download_log=$($download_tool_cmd)
        if [ $? -eq 0 ]; then
            check_sha256sum $1
            if [[ "$RESULT_CHECK_SHA256SUM" == "ok" ]]; then
                chmod 755 $MODDIR/tmp/$1
                mv $MODDIR/tmp/$1 $MODDIR/bin/$1
                RESULT_INSTALL_BINARY="ok"
                break
            fi
        # else
        #     echo "download_tool_cmd=[${download_tool_cmd}] return with [$?]. stderr=[${download_log}]" >> $EXTRA_LOG_SAVE_PATH/debug.log
        fi
    done
    rm -r "${MODDIR}/tmp/"
}

# 检查 ddns-go 支持哪些架构下的安卓系统
# 使用该函数之前必须确保 jq 程序可用
update_latest_release_info() {
    file_suffix_pattern="\.tar\.gz"
    if [[ x"$CURL_PATH" != "x" ]]; then
        download_tool_cmd="curl --silent --location "
    else
        download_tool_cmd="wget -q -O- "
    fi
    case "$GEOIP_LOCATION" in
        CN)
            api_url="https://github-api.sakurapuare.com/repos/jeessy2/ddns-go/releases/latest"
        ;;
        *)
            api_url="https://api.github.com/repos/jeessy2/ddns-go/releases/latest"
        ;;
    esac
    http_response=$($download_tool_cmd $api_url 2>/dev/null)
    # 用 jq 来读文件，echo 无论如何都会发生转译，复杂得很，printf '%s' $var 也不能用，试过了，不信可以试试
    # /system/bin/sh 特别辣鸡
    pre_proccess_content=$(jq -n "$http_response" | jq '.["assets"][].name' --raw-output | grep "android\_.*${file_suffix_pattern}$")
    filename_pattern=""
    # 这个地方有问题，需要改进 (TODO: 自己实现架构检测逻辑)
    # ARCH (string): the CPU architecture of the device. Value is either arm, arm64, x86, or x64
    case "$ARCH" in
        arm)
            for item in 7 6 5; do
                filename_pattern=$(echo -e "$pre_proccess_content" | grep "armv${item}${file_suffix_pattern}$")
                if [[ x"$filename_pattern" != "x" ]]; then
                    break
                fi
            done
        ;;
        arm64)
            filename_pattern=$(echo -e "$pre_proccess_content" | grep "arm64${file_suffix_pattern}$")
        ;;
        x86)
            filename_pattern=$(echo -e "$pre_proccess_content" | grep "i386${file_suffix_pattern}$")
        ;;
        x64)
            tmp_var=$(echo -e "$pre_proccess_content" | grep "x86\_64${file_suffix_pattern}$")
        ;;
        *)
            filename_pattern="arch_not_support"
        ;;
    esac
    if [[ x"$filename_pattern" == "x" || "$filename_pattern" == "arch_not_support" ]]; then
        LATEST_DOWNLOAD_URL=""
        LATEST_DOWNLOAD_URL_FILENAME=""
        LATEST_RELEASE_TAG_NAME="arch_not_support"
    else
        tmp_var=$(jq -n "$http_response" | jq '.["assets"][].browser_download_url' --raw-output | grep -F "$filename_pattern")
        # 这个镜像站下载的文件有问题， magic code 都不对了，得换
        tmp_var=$(echo -e "$tmp_var" | sed 's#\\##g' | sed 's#https://.*sakurapuare.com#https://github.com#g')
        LATEST_DOWNLOAD_URL="$(get_github_resource_download_url $tmp_var $GEOIP_LOCATION)"
        tmp_var=$(jq -n "$http_response" | jq '.["assets"][].name' --raw-output | grep -F "$filename_pattern")
        LATEST_DOWNLOAD_URL_FILENAME="$tmp_var"
        LATEST_RELEASE_TAG_NAME=$(jq -n "$http_response" | jq '.["tag_name"]' --raw-output)
    fi
}

# something else but not necessary
# 估计是原作者不知道如何解决 ash 下解析 JSON 
# 因为 JSON 确实难解析，所以偷懒取巧，写了个获取 tag name 的函数
# 实际上，有 jq 加持都不需要这样写了
# update_latest_release_tag_name() {
#     case "$GEOIP_LOCATION" in
#         CN)
#             curl -X GET --header 'Content-Type: application/json;charset=UTF-8' 'https://gitee.com/api/v5/repos/mirrors/Jeessy-DDNS-GO/tags?sort=updated&direction=desc&page=1&per_page=2' 2>/dev/null
#         ;;
#         *)
#             LATEST_RELEASE_TAG_NAME="$(curl -Ls "https://api.github.com/repos/jeessy2/ddns-go/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
#         ;;
#     esac
# }

# 本地版本号
get_version() {
    version="$("${MODDIR}/bin/ddns-go" -v 2>/dev/null || echo 0)"
}

generate_random_8bit_num() {
    tmp_num="$((RANDOM % 255 + 1))"
    while [ $(echo -e "$tmp_num" | wc -l) -lt 7 ]; do
        # 为避免循环多次，提高一次性生成完毕的概率
        item=0
        while [ $item -lt 10 ]; do
            tmp_num="$tmp_num\n$((RANDOM % 255 + 1))"
            item=$((item + 1))
        done
        tmp_num=$(echo -e "$tmp_num" | uniq)
    done
    # 只拿前面 7 个
    tmp_num=$(echo -e "$tmp_num" | head -n 7)

    echo -e "$tmp_num"
}

update_geoip_and_cloudflare_info() {
    for item in $(generate_random_8bit_num); do
        cdn_response=$(busybox wget -q -O- http://104.21.94.$item/cdn-cgi/trace 2>/dev/null)
        GEOIP_LOCATION=$(echo -e "$cdn_response" | grep 'loc=' | cut -d '=' -f 2)
        if [[ x"$GEOIP_LOCATION" != "x" ]]; then
            WORKED_CLOUDFLARE_CDN_NODE="104.21.94.$item"
            break
        fi
    done
}

# 检查网络连通性函数
check_connectivity() {
    RESULT_CHECK_CONNECTIVITY="failed"
    case "x$GEOIP_LOCATION" in
        xCN)
            if ping -q -c 1 -W 2 baidu.com 2>&1 >/dev/null; then
                RESULT_CHECK_CONNECTIVITY="ok"
            fi
        ;;
        x)
            if ping -q -c 1 -W 2 223.5.5.5 2>&1 >/dev/null; then
                RESULT_CHECK_CONNECTIVITY="ok"
            fi
        ;;
        *)
            if ping -q -c 1 -W 10 google.com 2>&1 >/dev/null; then
                RESULT_CHECK_CONNECTIVITY="ok"
            fi
        ;;
    esac
}

# 删除大于1MB的log.log文件
delete_log() {
    log_size=$(wc -c <"${EXTRA_LOG_SAVE_PATH}/info.log")
    if [[ "$log_size" -gt 1048576 ]]; then
        rm "${EXTRA_LOG_SAVE_PATH}/info.log"
    fi
}

download_ddns_go_archive_file() {
    mkdir -p "${MODDIR}/tmp"
    download_cmd="curl --silent --parallel --location --output ${MODDIR}/tmp/${LATEST_DOWNLOAD_URL_FILENAME} $LATEST_DOWNLOAD_URL"
    echo "[$(get_log_date)] $download_cmd" >> $EXTRA_LOG_SAVE_PATH/debug.log
    $download_cmd 2>&1 >> $EXTRA_LOG_SAVE_PATH/debug.log
    if [ $? -eq 0 ]; then
        chmod 755 "${MODDIR}/tmp/${LATEST_DOWNLOAD_URL_FILENAME}"
        return 0
    else
        return $?
    fi
}

extract_ddns_go_archive_file() {
    decompression_cmd="tar -xzf ${MODDIR}/tmp/${LATEST_DOWNLOAD_URL_FILENAME} -C ${MODDIR}/tmp"
    echo "[$(get_log_date)] $decompression_cmd" >> $EXTRA_LOG_SAVE_PATH/debug.log
    $decompression_cmd 2>&1 >> $EXTRA_LOG_SAVE_PATH/debug.log
    if [ $? -eq 0 ]; then
        mv -f "${MODDIR}/tmp/ddns-go" "${MODDIR}/bin/ddns-go"
        chmod 755 "${MODDIR}/bin/ddns-go"
        rm -r "${MODDIR}/tmp/"
        # RESULT_EXTRACT_DDNS_GO_ARCHIVE_FILE="true"
        return 0
    else
        # RESULT_EXTRACT_DDNS_GO_ARCHIVE_FILE="false"
        return $?
    fi
}

# 下载并解压更新包
download_and_extract() {
    download_ddns_go_archive_file
    extract_ddns_go_archive_file
}

# 比较版本号函数
version_ge() {
    test "$(echo -e "$1\n$2" | sort -V | tail -n 1)" = "$2"
}

# 更新列表并重启进程
update_and_restart() {
    get_version
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] ${version}，更新后" >>"${EXTRA_LOG_SAVE_PATH}/info.log"
    sed -i "s#^version=.*#version=${version}#g" "${MODDIR}/module.prop"
    if pgrep -f 'ddns-go' >/dev/null; then
        pkill ddns-go
    fi
    ASH_STANDALONE=1 busybox sh -c "$MODDIR/bin/ddns-go -l 127.0.0.1:9876 -dns 223.5.5.5 -c $MODDIR/config/ddns_go_config.yaml" &
}

# 更新失败
handle_failed_update() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 更新失败！" >>"${EXTRA_LOG_SAVE_PATH}/info.log"
}

# 更新检测
check_and_update_version() {
    # 获取最新版本号
    retry_times=0
    while true; do
        update_latest_release_info

        if [[ x"$LATEST_RELEASE_TAG_NAME" != "x" ]]; then
            break
        fi

        ((retry_times++))
        if [ $((retry_times % 60)) -eq 0 ]; then
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] 获取URL版本号失败..." >>"${EXTRA_LOG_SAVE_PATH}/info.log"
        fi

        sleep 5m
    done

    if [ ! -x "${MODDIR}/bin/ddns-go" ]; then
        echo "[$(get_log_date)] ${MODDIR}/bin/ddns-go 未找到，直接从URL进行更新..." >>"${EXTRA_LOG_SAVE_PATH}/info.log"
        download_and_extract
        update_and_restart
        return
    fi

    get_version
    if version_ge "${LATEST_RELEASE_TAG_NAME}" "${version}"; then
        echo "[$(date "+%Y-%m-%d %H:%M:%S")] ${version}，最新版本" >>"${EXTRA_LOG_SAVE_PATH}/info.log"
        sed -i "s#^version=.*#version=${version}#g" "${MODDIR}/module.prop"
    else
        echo "[$(get_log_date)] ${version}，更新中..." >>"${EXTRA_LOG_SAVE_PATH}/info.log"

        download_and_extract

        max_attempts=3 # 最大尝试次数
        attempt=1      # 当前尝试次数

        while [ $attempt -le $max_attempts ]; do
            sleep 10s
            get_version
            if [[ "${LATEST_RELEASE_TAG_NAME}" == "${version}" ]]; then
                update_and_restart
                break
            else
                ((attempt++))
                if [ $attempt -gt $max_attempts ]; then
                    handle_failed_update
                    break
                fi
                download_and_extract
            fi
        done
    fi
}

