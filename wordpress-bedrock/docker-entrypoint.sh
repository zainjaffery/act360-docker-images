#!/bin/bash


# Fix git ownership warning for bind-mounted repos
git config --global --add safe.directory "*" 2>/dev/null || true
# Source global shared env vars (SSH keys, config tokens, etc.)
if [ -f /etc/shared/env ]; then
    set -a
    source /etc/shared/env
    set +a
    echo "Shared env vars loaded"
fi
# Set up GitLab SSH key for Composer private repos
# Prefers shared volume at /etc/shared-ssh, falls back to COMPOSER_SSH_KEY env var
mkdir -p /root/.ssh
if [ -f /etc/shared/ssh/id_rsa ]; then
    cp /etc/shared/ssh/id_rsa /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
    [ -f /etc/shared/ssh/known_hosts ] && cp /etc/shared/ssh/known_hosts /root/.ssh/known_hosts
    echo "Composer SSH key loaded from shared volume"
elif [ -n "$COMPOSER_SSH_KEY" ]; then
    echo "$COMPOSER_SSH_KEY" | base64 -d > /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
    echo "Composer SSH key loaded from env var"
fi
ssh-keyscan -t rsa,ed25519 gitlab.com >> /root/.ssh/known_hosts 2>/dev/null

# Bedrock entrypoint: runs composer install if vendor/ is missing
if [ -f /var/www/html/composer.json ] && [ ! -d /var/www/html/vendor ]; then
    echo "vendor/ not found, running composer install..."
    cd /var/www/html
    if composer install --no-dev --optimize-autoloader --no-interaction; then
        echo "Composer install complete"
    else
        echo "================================================================" >&2
        echo "ERROR: composer install FAILED. Site will be broken (no vendor/)." >&2
        echo "SSH into the container, fix composer.json, run composer install," >&2
        echo "then restart the container." >&2
        echo "================================================================" >&2
    fi
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

# Persist all env vars for SSH sessions (sshd does not pass container env to login shells)
env | grep -E '^(DB_|WP_|TABLE_PREFIX|REDIS_|SSH_|SITE_NAME|AUTH_|SECURE_|LOGGED_|NONCE_)' > /etc/environment
chmod 644 /etc/environment

# Set default directory and source env for SSH login sessions
# SSH uses login shell which sources .bash_profile, not .bashrc
cat > /root/.bash_profile <<'BASHEOF'
cd /var/www/html
set -a
source /etc/environment 2>/dev/null
set +a
BASHEOF
cp /root/.bash_profile /root/.bashrc

# Auto-register SSH config in central repo (runs in background, non-blocking)
if [ -n "$SITE_NAME" ] && [ -n "$SSH_CONFIG_REPO" ]; then
    /usr/local/bin/register-ssh.sh &
fi

# Start supervisor (php-fpm + sshd)
exec /usr/bin/supervisord -c /etc/supervisord.conf
