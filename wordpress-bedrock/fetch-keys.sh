#!/bin/bash
# fetch-keys.sh - AuthorizedKeysCommand script
# Fetches authorized SSH keys from a URL (GitHub raw, GitLab raw, or any URL)
#
# Set SSH_KEYS_URL to the raw URL of your keys file
# For private GitLab repos, also set SSH_KEYS_TOKEN (Personal/Project Access Token with read_repository scope)
# For private GitHub repos, set SSH_KEYS_TOKEN (Personal Access Token with repo scope)
#
# GitLab note: this script auto-converts /-/raw/ URLs to /api/v4/ since GitLab
# rejects PAT auth on /raw/ URLs (those require session cookies).

USERNAME="$1"
SSH_KEYS_URL="${SSH_KEYS_URL:-}"
SSH_KEYS_TOKEN="${SSH_KEYS_TOKEN:-}"

if [ -z "$SSH_KEYS_URL" ]; then
    cat /root/.ssh/authorized_keys 2>/dev/null
    exit 0
fi

# For private GitLab raw URLs, convert to API endpoint that accepts PAT auth.
# Pattern: https://gitlab.com/<group>/<project>/-/raw/<ref>/<path>?...
#      -> https://gitlab.com/api/v4/projects/<url-encoded-group/project>/repository/files/<url-encoded-path>/raw?ref=<ref>
if [ -n "$SSH_KEYS_TOKEN" ] && echo "$SSH_KEYS_URL" | grep -qE 'gitlab\.[^/]+/.+/-/raw/'; then
    HOST=$(echo "$SSH_KEYS_URL" | sed -E 's|^(https?://[^/]+)/.*|\1|')
    PROJECT_PATH=$(echo "$SSH_KEYS_URL" | sed -E 's|^https?://[^/]+/(.+)/-/raw/.*|\1|')
    REF_AND_FILE=$(echo "$SSH_KEYS_URL" | sed -E 's|^https?://[^/]+/.+/-/raw/(.*)|\1|' | sed 's/?.*$//')
    REF=$(echo "$REF_AND_FILE" | cut -d/ -f1)
    FILE_PATH=$(echo "$REF_AND_FILE" | cut -d/ -f2-)
    # URL-encode slashes in project path and file path
    ENCODED_PROJECT=$(echo "$PROJECT_PATH" | sed 's|/|%2F|g')
    ENCODED_FILE=$(echo "$FILE_PATH" | sed 's|/|%2F|g')
    SSH_KEYS_URL="$HOST/api/v4/projects/$ENCODED_PROJECT/repository/files/$ENCODED_FILE/raw?ref=$REF"
fi

# Build auth header
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
    RESULT=$(curl -sfL --connect-timeout 5 --max-time 10 -H "$AUTH_HEADER" "$SSH_KEYS_URL" 2>/dev/null)
else
    RESULT=$(curl -sfL --connect-timeout 5 --max-time 10 "$SSH_KEYS_URL" 2>/dev/null)
fi

if [ -n "$RESULT" ]; then
    echo "$RESULT"
else
    cat /root/.ssh/authorized_keys 2>/dev/null
fi
