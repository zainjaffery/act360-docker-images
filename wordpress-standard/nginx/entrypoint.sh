#!/bin/sh
# nginx-entrypoint.sh
# Generates htpasswd and auth config for non-production environments

AUTH_CONF="/etc/nginx/conf.d/auth.conf"
HTPASSWD_FILE="/etc/nginx/conf.d/.htpasswd"

if [ "$ENVIRONMENT" != "production" ]; then
    # Generate htpasswd file (act360 / development)
    # Pre-computed hash to avoid needing openssl in the container
    printf 'act360:$apr1$YogpjUpM$lB6M6fenOQk0LfGyXGBcX/\n' > "$HTPASSWD_FILE"

    # Create auth config snippet that gets included by the main config
    cat > "$AUTH_CONF" <<'EOF'
# Basic auth enabled for non-production
auth_basic "Restricted";
auth_basic_user_file /etc/nginx/conf.d/.htpasswd;
EOF
    echo "Basic auth ENABLED (non-production)"
else
    # Empty auth config for production
    echo "# No auth for production" > "$AUTH_CONF"
    rm -f "$HTPASSWD_FILE"
    echo "Basic auth DISABLED (production)"
fi
