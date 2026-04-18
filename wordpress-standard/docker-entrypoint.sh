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
