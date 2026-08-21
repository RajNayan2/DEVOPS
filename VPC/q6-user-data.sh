#!/bin/bash

apt-get update -y
apt-get install nginx -y

PRIVATE_IP=$(hostname -I | awk '{print $1}')

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
<title>Assignment 7</title>
</head>
<body>
<h1>Assignment 7 - Public Web Server</h1>
<p>Nginx is running successfully.</p>
<p>Private IP: $PRIVATE_IP</p>
</body>
</html>
EOF

systemctl enable nginx
systemctl start nginx
