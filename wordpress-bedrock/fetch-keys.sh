#!/bin/bash
# fetch-keys.sh - AuthorizedKeysCommand script
# Fetches authorized SSH keys from a URL (e.g., raw GitHub file)
# Set SSH_KEYS_URL environment variable to the raw URL of your keys file
#
# Each line in the remote file can optionally include environment variables:
# environment="GIT_AUTHOR_NAME=John Doe,GIT_AUTHOR_EMAIL=john@example.com" ssh-rsa AAAA... john@laptop

USERNAME="$1"
SSH_KEYS_URL="${SSH_KEYS_URL:-}"

if [ -z "$SSH_KEYS_URL" ]; then
    # Fallback to local authorized_keys
    cat /root/.ssh/authorized_keys 2>/dev/null
    exit 0
fi

# Fetch keys from remote URL with 5 second timeout
curl -sf --connect-timeout 5 --max-time 10 "$SSH_KEYS_URL" 2>/dev/null

# If curl fails, fall back to local keys
if [ $? -ne 0 ]; then
    cat /root/.ssh/authorized_keys 2>/dev/null
fi
