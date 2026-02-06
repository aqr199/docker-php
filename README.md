# 在 docker 環境架設 php 伺服器

使用 rockylinux 建立 PHP 伺服器

# 版本問題

rockylinux:8 可以安裝 PHP 7.2~8.5

rockylinux:9 可以安裝 PHP 7.4~8.5

rockylinux:10 可以安裝 PHP 7.4~8.5

rockylinux:10 不支援舊CPU, 需要 v3 以上

!!! 如何檢查 CPU 支援

```
awk '/flags/ {
    v2=($0~"sse4_2" && $0~"popcnt"); 
    v3=($0~"avx2" && $0~"bmi1" && $0~"bmi2" && $0~"fma" && $0~"movbe");
    if (v3) print "支援 Rocky 8, 9, 10 (x86-64-v3)";
    else if (v2) print "支援 Rocky 8, 9 (x86-64-v2)";
    else print "僅支援 Rocky 8 (x86-64-v1)";
    exit;
}' /proc/cpuinfo
```

# 安裝軟體

主要為 httpd, php-fpm, nginx
透過在 docker-compose.yml 設定切換 httpd 及 nginx

```
      - CONTAINER_MODE=nginx
#      - CONTAINER_MODE=apache
#      - CONTAINER_MODE=php-fpm
```

# PHP 設定

建立 my-php-custom.ini

```
# my-php-custom.ini 範例
upload_max_filesize = 128M
post_max_size = 128M
memory_limit = 512M
date.timezone = "Asia/Taipei"
```

掛載檔案到 /etc/php.d/ 目錄下

```
volumes:
    # 關鍵：掛載自定義設定到 Rocky Linux 的 PHP 配置目錄
    - ./my-php-custom.ini:/etc/php.d/99-custom.ini:ro
```


# httpd 設定

網站設定目錄 /etc/httpd/site.d


!!! 單一網站掛載
```
volumes:
    - ./httpd_www.conf:/etc/httpd/site.d/www.conf:ro
```

!!! 整個目錄掛載

```
volumes:
    - ./httpd_site:/etc/httpd/site.d:ro
```

!!! 修改設定檔, 不需重啟 container

```
docker exec -it <容器名稱或ID> apachectl -k graceful
```

!!! 檢查設定檔是否正確

```
docker exec -it <容器名稱或ID> apachectl configtest
```

# nginx 設定

網站設定目錄 /etc/nginx/site.d

!!! 單一網站掛載
```
volumes:
    - ./nginx_www.conf:/etc/nginx/site.d/www.conf:ro
```

!!! 整個目錄掛載

```
volumes:
    - ./nginx_site:/etc/nginx/site.d:ro
```

模組載入設定 /etc/nginx/modules.conf

```
load_module modules/ngx_http_js_module.so;
```

掛載檔案到 /etc/nginx/modules.conf

```
volumes:
    - ./modules.conf:/etc/nginx/modules.conf:ro
```

!!! 修改設定檔, 不需重啟 container

```
docker exec <容器名稱或ID> nginx -s reload
```

!!! 檢查設定檔是否正確

```
docker exec <容器名稱或ID> nginx -t
```

# php-fpm 設定

!!! 使用 80 PORT 進行連線

設定目錄: /etc/php-fpm.d

設定目錄: /etc/php-fpm.d/www.conf


!!! 單一網站掛載
```
volumes:
    - ./php-fpm_www.conf:/etc/php-fpm.d/www.conf:ro
```

!!! 整個目錄掛載

```
volumes:
    - ./php-fpm_site:/etc/php-fpm.d:ro
```


!!! 修改設定檔, 不需重啟 container

這是最直接的方法，透過 kill 指令發送 -USR2 訊號給容器內的 1 號進程（在標準鏡像中，1 號通常就是 php-fpm）。

```
docker exec -it <container_name_or_id> kill -USR2 1

```

如果你不確定進程 ID，可以使用 pkill 根據名稱來觸發
```
docker exec -it <container_name_or_id> pkill -o -USR2 php-fpm
```

!!! 檢查設定檔是否正確

```
docker exec -it <container_name_or_id> php-fpm -t
```






