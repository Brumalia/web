#!/bin/bash
set -e

cd /var/www/html

echo 'Migrating database...'
php artisan migrate

echo 'Verifying permissions'
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html/storage

exec "$@"