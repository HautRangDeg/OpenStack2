#!/bin/bash

set -e

doas apk update
doas apk add  Nginx
doas rc-update add Nginx
doas rc-service nginx start


doas tee /etc/nginx/http.d/default.conf > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name _;

    root /var/www/localhost/htdocs;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF


doas tee /var/www/localhost/htdocs/index.html > /dev/null <<EOF
<!DOCTYPE html>
<html>
<head>
 <title>Fred serveur</title>
</head>
<body>
 <h1>Serveur : $HOSTNAME</h1>
   <p>heberge par Microstack</>
 </body>
</html>
EOF


doas rc-service nginx restart

echo "Installation Nginx terminée"


