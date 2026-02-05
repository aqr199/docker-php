# 使用具體的版本標籤確保環境可重現
FROM rockylinux/rockylinux:8.10-minimal
#FROM rockylinux/rockylinux:9.7.20251123-minimal

ENV PHP_VER=7.3
ENV REMI_VER=8

#ENV PHP_VER=8.1
#ENV REMI_VER=9

COPY nginx.repo /etc/yum.repos.d/

# 1. 合併安裝與清理命令，減少 Layer 數量並降低映像檔體積
# 2. 使用具體的套件清單，避免安裝不必要的依賴
RUN microdnf install -y epel-release && \
    curl -O http://rpms.remirepo.net/enterprise/remi-release-${REMI_VER}.rpm && \
    rpm -ivh remi-release-${REMI_VER}.rpm && \
    rm -f remi-release-${REMI_VER}.rpm && \
    microdnf module reset php -y && \
    microdnf module enable php:remi-${PHP_VER} -y && \
#    microdnf install --nodocs --setopt=install_weak_deps=0 -y \
    microdnf install --nodocs -y \
        httpd \
        mod_ssl \
        php \
        php-fpm \
        php-mysqlnd \
        php-zip \
        php-gd \
        php-redis \
        tzdata less findutils && \
#    microdnf --enablerepo=remi install --nodocs -y \
#        php-pecl-imagick-im7 \
#        ImageMagick && \
    microdnf install --enablerepo=nginx-mainline --nodocs -y \
        nginx \
        nginx-module-njs \
        nginx-module-otel \
        nginx-module-acme \
        nginx-module-image-filter \
        nginx-module-xslt \
        nginx-module-perl && \
    # 配置 Apache 與清理
    ln -sf /dev/stdout /var/log/httpd/access_log && \
    ln -sf /dev/stderr /var/log/httpd/error_log && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    ln -sf /dev/stderr /var/log/php-fpm/www-error.log && \
    mkdir -p /run/php-fpm /etc/httpd/ssl /etc/httpd/site.d /etc/nginx/site.d && \
    sed -i '/<VirtualHost _default_:443>/,/<\/VirtualHost>/d' /etc/httpd/conf.d/ssl.conf && \
    touch /etc/nginx/modules.conf && \
    echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf && \
    echo "IncludeOptional site.d/*.conf" >> /etc/httpd/conf/httpd.conf && \
    sed -i 's/^LoadModule lbmethod_heartbeat_module/#LoadModule lbmethod_heartbeat_module/' /etc/httpd/conf.modules.d/00-proxy.conf && \
    microdnf clean all && \
    rm -rf /etc/nginx/conf.d/default.conf && \
    rm -rf /etc/nginx/nginx.conf && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/* /var/tmp/*

# 將配置文件拷貝放在安裝之後，這樣修改配置時不需要重新執行耗時的安裝過程
COPY html/index.php /var/www/html/
COPY html/.htaccess /var/www/html/
COPY nginx_web.conf /etc/nginx/site.d/000-default.conf
COPY localhost.conf /etc/httpd/site.d/
COPY entrypoint.sh /

COPY nginx.conf /etc/nginx/

# 設置權限與工作目錄
RUN chmod +x /entrypoint.sh
WORKDIR /var/www/html

EXPOSE 80 443

# 使用 ENTRYPOINT 配合 CMD 是 Docker 的最佳實踐
# entrypoint.sh 應該負責啟動 PHP-FPM 並執行 httpd -D FOREGROUND
ENTRYPOINT ["/entrypoint.sh"]

