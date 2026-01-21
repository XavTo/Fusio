#!/usr/bin/env bash
set -euo pipefail

echo "[railway] Fix Apache MPM…"
rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.* 2>/dev/null || true
a2dismod mpm_event 2>/dev/null || true
a2dismod mpm_worker 2>/dev/null || true
a2enmod mpm_prefork 2>/dev/null || true

# Railway attend que le process écoute sur $PORT (variable injectée)
# https://docs.railway.com/guides/public-networking
if [[ -n "${PORT:-}" ]]; then
  echo "[railway] Bind Apache to PORT=${PORT}"
  sed -i "s/^Listen .*/Listen ${PORT}/" /etc/apache2/ports.conf || true
  sed -i "s/:80>/:${PORT}>/g" /etc/apache2/sites-enabled/000-default.conf 2>/dev/null || true
fi

# Démarre l’entrypoint Fusio d’origine si présent, sinon fallback
if [[ -x "/docker-entrypoint.sh" ]]; then
  exec /docker-entrypoint.sh "$@"
elif [[ -x "/usr/local/bin/docker-entrypoint.sh" ]]; then
  exec /usr/local/bin/docker-entrypoint.sh "$@"
else
  exec supervisord -c /etc/supervisor/supervisord.conf
fi
