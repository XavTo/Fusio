echo "[railway] Configure Apache vhost for Fusio…"

# évite les warnings ServerName
echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf
a2enconf servername >/dev/null 2>&1 || true

# modules requis
a2enmod rewrite >/dev/null 2>&1 || true

# VHost : IMPORTANT => DocumentRoot sur fusio/public
cat > /etc/apache2/sites-available/000-default.conf <<EOF
<VirtualHost *:${PORT}>
    ServerName localhost
    DocumentRoot /var/www/html/fusio/public

    <Directory /var/www/html/fusio/public>
        Options FollowSymLinks
        AllowOverride All
        Require all granted

        RewriteEngine On
        RewriteBase /

        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule (.*) /index.php/\$1 [L]

        RewriteCond %{HTTP:Authorization} ^(.*)
        RewriteRule .* - [e=HTTP_AUTHORIZATION:%1]
    </Directory>
</VirtualHost>
EOF
