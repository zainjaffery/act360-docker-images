#!/bin/bash
# fetch-keys.sh - AuthorizedKeysCommand script
# Fetches authorized SSH keys from a URL (GitHub raw, GitLab raw, or any URL)
#
# Set SSH_KEYS_URL to the raw URL of your keys file
# For private GitLab repos, also set SSH_KEYS_TOKEN (Personal Access Token or Project Access Token with read_repository scope)
# For private GitHub repos, set SSH_KEYS_TOKEN (Personal Access Token with repo scope)
#
# Each line in the remote file can optionally include environment variables:
# environment="GIT_AUTHOR_NAME=John Doe,GIT_AUTHOR_EMAIL=john@example.com" ssh-rsa AAAA... john@laptop

USERNAME="$1"
SSH_KEYS_URL="${SSH_KEYS_URL:-}"
SSH_KEYS_TOKEN="${SSH_KEYS_TOKEN:-}"

if [ -z "$SSH_KEYS_URL" ]; then
    cat /root/.ssh/authorized_keys 2>/dev/null
    exit 0
fi

# Build curl auth header based on URL host
AUTH_HEADER=""
if [ -n "$SSH_KEYS_TOKEN" ]; then
    if echo "$SSH_KEYS_URL" | grep -q "gitlab"; then
        AUTH_HEADER="PRIVATE-TOKEN: $SSH_KEYS_TOKEN"
    elif echo "$SSH_KEYS_URL" | grep -q "github"; then
        AUTH_HEADER="Authorization: token $SSH_KEYS_TOKEN"
    else
        AUTH_HEADER="Authorization: Bearer $SSH_KEYS_TOKEN"
    fi
fi

# Fetch keys
if [ -n "$AUTH_HEADER" ]; then
    curl -sfL --connect-timeout 5 --max-time 10 -H "$AUTH_HEADER" "$SSH_KEYS_URL" 2>/dev/null
else
    curl -sfL --connect-timeout 5 --max-time 10 "$SSH_KEYS_URL" 2>/dev/null
fi

# Fall back to local keys if fetch failed
if [ $? -ne 0 ]; then
    cat /root/.ssh/authorized_keys 2>/dev/null
fi
