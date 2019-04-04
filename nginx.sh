#!/bin/bash
amazon-linux-extras install -y nginx1.12
cat > /etc/ssl/certs/make-dummy-cert-new <<'_END'
#!/bin/sh
umask 077
answers() {
        echo --
        echo SomeState
        echo SomeCity
        echo SomeOrganization
        echo SomeOrganizationalUnit
        echo localhost.localdomain
        echo root@localhost.localdomain
}
if [ $# -eq 0 ] ; then
        echo $"Usage: `basename $0` file.key file.crt [...]"
        exit 0
fi
answers | /usr/bin/openssl req -newkey rsa:2048 -keyout $1 -nodes -x509 -days 365 -out $2 2> /dev/null
_END

# creata a vanilla nginx.conf that enable both HTTP and HTTPS
cat > /etc/nginx/nginx.conf <<'_END'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /usr/share/nginx/html;

        include /etc/nginx/default.d/*.conf;

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }

# HTTPS
    server {
        listen       443 ssl http2 default_server;
        listen       [::]:443 ssl http2 default_server;
        server_name  _;
        root         /usr/share/nginx/html;

        ssl_certificate "/etc/ssl/certs/nginx-selfsigned.crt";
        ssl_certificate_key "/etc/ssl/certs/nginx-selfsigned.key";
        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout  10m;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;
        include /etc/nginx/default.d/*.conf;
        location / {
        }
        error_page 404 /404.html;
            location = /40x.html {
        }
        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }
}
_END
/bin/sh /etc/ssl/certs/make-dummy-cert-new /etc/ssl/certs/nginx-selfsigned.key  /etc/ssl/certs/nginx-selfsigned.crt
systemctl restart nginx.service
systemctl enable nginx.service
