#!/bin/sh
# Generates htpasswd and auth config for non-production environments

AUTH_CONF="/etc/nginx/conf.d/auth.conf"

if [ "$WP_ENV" != "production" ] && [ "$ENVIRONMENT" != "production" ]; then
    printf 'act360:$apr1$I4fi2/30$2SiLLJMli5c51xJCcU4ap.\n' > /etc/nginx/.htpasswd
    cat > "$AUTH_CONF" <<'EOF'
auth_basic "Restricted";
auth_basic_user_file /etc/nginx/.htpasswd;
EOF
    echo "Basic auth ENABLED (non-production)"
else
    echo "# No auth for production" > "$AUTH_CONF"
    echo "Basic auth DISABLED (production)"
fi
