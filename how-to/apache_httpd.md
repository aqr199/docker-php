# 實務使用筆記


連線非本機 php-fpm

單一網站

```
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html

    # 將所有 .php 檔案轉交給 php-fpm 容器
    <FilesMatch \.php$>
        SetHandler "proxy:fcgi://192.168.50.123:80"
    </FilesMatch>

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

全域設定

建立 php.conf

```
<IfModule !mod_php5.c>
  <IfModule !mod_php7.c>
    # Enable http authorization headers
    SetEnvIfNoCase ^Authorization$ "(.+)" HTTP_AUTHORIZATION=$1

    <FilesMatch \.(php|phar)$>
        SetHandler "proxy:fcgi://192.168.50.123:80"
    </FilesMatch>
  </IfModule>
</IfModule>
```

掛載到 /etc/httpd/conf.d/zz-php.conf
複寫原來設定, 使用 zz 開頭檔案, 確認設定檔最後載入





