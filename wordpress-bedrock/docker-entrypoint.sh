#!/bin/bash
# Bedrock entrypoint: runs composer install if vendor/ is missing

if [ -f /var/www/html/composer.json ] && [ ! -d /var/www/html/vendor ]; then
    echo "vendor/ not found, running composer install..."
    cd /var/www/html && composer install --no-dev --optimize-autoloader --no-interaction
    chown -R www-data:www-data /var/www/html
    echo "Composer install complete"
fi

# Ensure uploads directory exists and is writable
if [ -d /var/www/html/web ]; then
    mkdir -p /var/www/html/web/app/uploads
    chown -R www-data:www-data /var/www/html/web/app/uploads
fi

# Start supervisor (php-fpm + sshd)
exec /usr/bin/supervisord -c /etc/supervisord.conf
