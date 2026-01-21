FROM fusio/fusio:6.2

# Fusio utilise Apache + PHP en module (pas FCGI), donc MPM prefork est le choix le plus compatible
# On force un seul MPM actif pour éviter "More than one MPM loaded"
RUN a2dismod mpm_event mpm_worker || true \
 && a2enmod mpm_prefork || true

# (optionnel mais souvent utile)
RUN a2enmod rewrite headers || true
