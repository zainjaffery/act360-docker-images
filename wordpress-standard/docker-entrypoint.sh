#!/bin/bash
# Download WordPress if not already present
if [ ! -f /var/www/html/wp-login.php ]; then
    echo "WordPress not found, downloading..."
    wp core download --path=/var/www/html --allow-root
    chown -R www-data:www-data /var/www/html
    echo "WordPress downloaded successfully"
else
    echo "WordPress already installed, skipping download"
fi

# Start supervisor (php-fpm + sshd)
exec /usr/bin/supervisord -c /etc/supervisord.conf
