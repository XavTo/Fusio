#!/usr/bin/env bash
set -euo pipefail

echo "[railway] Starting Fusio entrypoint…"

###############################################################################
# 1) Apache MPM FIX (évite: More than one MPM loaded)
###############################################################################
echo "[railway] Fix Apache MPM…"

# Désactiver explicitement les MPM incompatibles
rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.* 2>/dev/null || true
a2dismod mpm_event >/dev/null 2>&1 || true
a2dismod mpm_worker >/dev/null 2>&1 || true

# Activer prefork (requis avec PHP mod_apache)
a2enmod mpm_prefork >/dev/null 2>&1 || true

###############################################################################
# 2) Apache modules requis par Fusio
###############################################################################
echo "[railway] Enable Apache modules…"
a2enmod rewrite headers >/dev/null 2>&1 || true

###############################################################################
# 3) ServerName (supprime warning AH00558)
###############################################################################
echo "[railway] Configure ServerName…"
echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf
a2enconf servername >/dev/null 2>&1 || true

###############################################################################
# 4) Port Railway (IMPORTANT)
###############################################################################
# Railway injecte PORT automatiquement → Apache DOIT écouter dessus
if [[ -n "${PORT:-}" ]]; then
  echo "[railway] Bind Apache to PORT=${PORT}"

  sed -i "s/^Listen .*/Listen ${PORT}/" /etc/apache2/ports.conf || true
fi

###############################################################################
# 5) VirtualHost Fusio (DocumentRoot CORRECT)
###############################################################################
echo "[railway] Configure Apache vhost for Fusio…"

cat > /etc/apache2/sites-available/000-default.conf <<EOF
<VirtualHost *:${PORT:-80}>
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

###############################################################################
# 6) Sécurité minimale (permissions)
###############################################################################
echo "[railway] Fix permissions…"
chown -R www-data:www-data /var/www/html/fusio || true

###############################################################################
# 7) Lancer l’entrypoint officiel Fusio
###############################################################################
echo "[railway] Hand off to Fusio entrypoint…"

# Selon la version de l’image
if [[ -x "/docker-entrypoint.sh" ]]; then
  exec /docker-entrypoint.sh "$@"
elif [[ -x "/usr/local/bin/docker-entrypoint.sh" ]]; then
  exec /usr/local/bin/docker-entrypoint.sh "$@"
else
  echo "[railway] No Fusio entrypoint found, starting supervisord directly"
  exec supervisord -c /etc/supervisor/supervisord.conf
fi
