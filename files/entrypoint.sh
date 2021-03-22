#!/bin/bash
set -e

cd /var/www/html

# Only migrate if installed
if [[ -f /var/www/html/.installed ]]; then
  echo 'Migrating database...'
  php artisan migrate
fi

echo 'Verifying permissions'
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html/storage

exec "$@"