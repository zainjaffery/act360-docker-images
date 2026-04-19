#!/bin/bash
# Bedrock entrypoint: runs composer install if vendor/ is missing

if [ -f /var/www/html/composer.json ] && [ ! -d /var/www/html/vendor ]; then
    echo "vendor/ not found, running composer install..."
    cd /var/www/html && composer install --no-dev --optimize-autoloader --no-interaction
    echo "Composer install complete"
fi

# Ensure uploads directory exists and is writable
if [ -d /var/www/html/web ]; then
    mkdir -p /var/www/html/web/app/uploads
fi

# Always ensure www-data owns the web root so PHP can write
echo "Setting ownership on /var/www/html to www-data..."
chown -R www-data:www-data /var/www/html

# Persist SSH key fetcher env vars to a file so sshd's AuthorizedKeysCommand
# subprocesses can read them (sshd does not pass container env vars through)
cat > /etc/ssh-keys.env <<EOF
SSH_KEYS_URL="${SSH_KEYS_URL:-}"
SSH_KEYS_TOKEN="${SSH_KEYS_TOKEN:-}"
EOF
chmod 644 /etc/ssh-keys.env

# Auto-register SSH config in central repo (runs in background, non-blocking)
if [ -n "$SITE_NAME" ] && [ -n "$SSH_CONFIG_REPO" ]; then
    /usr/local/bin/register-ssh.sh &
fi

# Start supervisor (php-fpm + sshd)
exec /usr/bin/supervisord -c /etc/supervisord.conf
