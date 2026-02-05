#!/bin/bash
# -e: 遇錯即停
# -u: 遇到未定義變數報錯
# -o pipefail: 捕捉管道命令中的錯誤
set -euo pipefail

# --- 隱藏版本資訊函數 ---
hide_versions() {
    echo "[INFO] Applying security hardening (hiding versions)..."
    # PHP
    [ -f /etc/php.ini ] && sed -i 's/^expose_php =.*/expose_php = Off/' /etc/php.ini
    
    # Apache
    if [ -f /etc/httpd/conf/httpd.conf ]; then
#        sed -i 's/^ServerTokens.*/ServerTokens Prod/' /etc/httpd/conf/httpd.conf || echo "ServerTokens Prod" >> /etc/httpd/conf/httpd.conf
#        sed -i 's/^ServerSignature.*/ServerSignature Off/' /etc/httpd/conf/httpd.conf || echo "ServerSignature Off" >> /etc/httpd/conf/httpd.conf
         echo "ServerTokens Prod" >> /etc/httpd/conf/httpd.conf
         echo "ServerSignature Off" >> /etc/httpd/conf/httpd.conf
    fi

    # Nginx
    [ -f /etc/nginx/nginx.conf ] && sed -i '/http {/a \    server_tokens off;' /etc/nginx/nginx.conf
}


echo "[INFO] Starting container initialization..."

# 1. 動態設定時區 (通用邏輯)
if [ -n "${TZ:-}" ]; then
    echo "[INFO] Setting timezone to ${TZ}"
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
    echo "${TZ}" > /etc/timezone
    
    PHP_INI="/etc/php.ini"
    if [ -f "$PHP_INI" ]; then
        sed -i "s|;date.timezone =.*|date.timezone = ${TZ}|" "$PHP_INI"
        # 如果 www.conf 存在才寫入
        if [ -f "/etc/php-fpm.d/www.conf" ]; then
            echo "php_admin_value[date.timezone] = ${TZ}" >> /etc/php-fpm.d/www.conf
        fi
    fi
fi

# 執行隱藏邏輯
hide_versions

# 2. 根據模式啟動服務
MODE="${CONTAINER_MODE:-apache}"
echo "[INFO] Starting container initialization in '$MODE' mode..."

if [ "$MODE" = "php-fpm" ]; then
    echo "[INFO] Configuring PHP-FPM to listen on port 80..."
    PHP_FPM_CONF="/etc/php-fpm.d/www.conf"
    
    # 修改監聽埠號為 80
    sed -i 's/^listen =.*/listen = 0.0.0.0:80/' "$PHP_FPM_CONF"
    
    # 記得註釋掉限制客戶端的設定，否則外部連不進來
    sed -i 's/^listen.allowed_clients/;listen.allowed_clients/' "$PHP_FPM_CONF"
fi

case "$MODE" in
    "apache")
        echo "[INFO] Starting PHP-FPM..."
        php-fpm -t
        php-fpm
        echo "[INFO] Mode: Apache"
        apachectl configtest
        exec httpd -D FOREGROUND
        ;;

    "nginx")
        echo "[INFO] Starting PHP-FPM..."
        php-fpm -t
        php-fpm
        echo "[INFO] Mode: Nginx"
        nginx -t
        exec nginx -g "daemon off;"
        ;;

#    "php-fpm")
#        echo "[INFO] Mode: PHP-FPM"
#        php-fpm -t
#        exec php-fpm -F
#        ;;
     *)
        echo "[ERROR] Unknown mode: $MODE"
        echo "Available modes: apache, nginx"
        exit 1
        ;;
esac

