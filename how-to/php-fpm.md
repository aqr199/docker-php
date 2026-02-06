# 實務使用筆記

要掛載與 httpd 或 nginx 一樣WEB目錄結構

```
services:
  web:
    ...
    environment:
      - CONTAINER_MODE=php-fpm
    volumes:
      # 將網頁程式碼掛載進去
      - ./html:/var/www/html
    ...
```