#!/bin/bash
# Download WordPress if not already present
if [ ! -f /var/www/html/wp-login.php ]; then
    echo "WordPress not found, downloading..."
    wp core download --path=/var/www/html --allow-root
    echo "WordPress downloaded successfully"
else
    echo "WordPress already installed, skipping download"
fi

# Always ensure www-data owns the web root so PHP can write wp-config.php, uploads, etc.
echo "Setting ownership on /var/www/html to www-data..."
chown -R www-data:www-data /var/www/html

# Start supervisor (php-fpm + sshd)
exec /usr/bin/supervisord -c /etc/supervisord.conf
