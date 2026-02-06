# 實務使用筆記

連線非本機 php-fpm

單一網站

```
server {
    listen 80;
    server_name localhost;

    # 這裡必須與 PHP-FPM 容器內的程式碼路徑一致
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # 處理 PHP 檔案轉發
    location ~ \.php$ {
        # 轉發到 PHP-FPM 容器的 IP 與 Port
        fastcgi_pass 192.168.50.123:80;
        fastcgi_index index.php;
        
        # 這是最關鍵的一行，告知 PHP-FPM 要執行哪個路徑下的檔案
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        
        include fastcgi_params;
    }
}
```

全域設定

建立 php-fpm.conf 檔案

```
upstream php-fpm {
    server 192.168.50.123:80;
}
```
掛載到 /etc/nginx/conf.d/php-fpm.conf
複寫原來設定




