#!/bin/bash
# register-ssh.sh - Auto-registers this container's SSH config in a central GitLab repo
#
# Runs on container boot. Uses BEGIN/END markers for idempotent updates (no duplicates).
# Requires: SITE_NAME, SSH_PORT, SSH_HOST, SSH_CONFIG_REPO, SSH_CONFIG_TOKEN, SSH_CONFIG_FILE
#
# The script clones the config repo, updates the entry for this site, and pushes.
# If the entry already exists with the same values, no commit is made.

SITE_NAME="${SITE_NAME:-}"
SSH_PORT="${SSH_PORT:-2222}"
SSH_HOST="${SSH_HOST:-}"
SSH_CONFIG_REPO="${SSH_CONFIG_REPO:-}"
SSH_CONFIG_TOKEN="${SSH_CONFIG_TOKEN:-}"
SSH_CONFIG_FILE="${SSH_CONFIG_FILE:-act360-dev}"

# All vars required
if [ -z "$SITE_NAME" ] || [ -z "$SSH_HOST" ] || [ -z "$SSH_CONFIG_REPO" ] || [ -z "$SSH_CONFIG_TOKEN" ]; then
    echo "register-ssh: skipping (SITE_NAME, SSH_HOST, SSH_CONFIG_REPO, or SSH_CONFIG_TOKEN not set)"
    exit 0
fi

WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

# Build the SSH config block
CONFIG_BLOCK="# === BEGIN ${SITE_NAME} ===
Host ${SITE_NAME}
    HostName 127.0.0.1
    Port ${SSH_PORT}
    User root
    ProxyJump act360@${SSH_HOST}
    LocalForward 3306 db:3306
# === END ${SITE_NAME} ==="

# Clone the config repo
# Inject token into HTTPS URL: https://oauth2:TOKEN@gitlab.com/...
REPO_URL=$(echo "$SSH_CONFIG_REPO" | sed "s|https://|https://oauth2:${SSH_CONFIG_TOKEN}@|")

echo "register-ssh: cloning config repo..."
git clone --depth 1 "$REPO_URL" "$WORK_DIR/repo" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "register-ssh: failed to clone config repo"
    exit 1
fi

cd "$WORK_DIR/repo"
CONFIG_PATH="$WORK_DIR/repo/$SSH_CONFIG_FILE"

# Create file if it doesn't exist
if [ ! -f "$CONFIG_PATH" ]; then
    touch "$CONFIG_PATH"
fi

# Check if entry already exists with same content
if grep -q "# === BEGIN ${SITE_NAME} ===" "$CONFIG_PATH"; then
    # Extract existing block
    EXISTING=$(sed -n "/# === BEGIN ${SITE_NAME} ===/,/# === END ${SITE_NAME} ===/p" "$CONFIG_PATH")
    if [ "$EXISTING" = "$CONFIG_BLOCK" ]; then
        echo "register-ssh: entry for ${SITE_NAME} already up to date, skipping"
        exit 0
    fi
    # Remove old entry (will be replaced)
    sed -i "/# === BEGIN ${SITE_NAME} ===/,/# === END ${SITE_NAME} ===/d" "$CONFIG_PATH"
    echo "register-ssh: updating entry for ${SITE_NAME}"
else
    echo "register-ssh: adding new entry for ${SITE_NAME}"
fi

# Append the new block
echo "" >> "$CONFIG_PATH"
echo "$CONFIG_BLOCK" >> "$CONFIG_PATH"

# Remove any double blank lines
sed -i '/^$/N;/^\n$/d' "$CONFIG_PATH"

# Commit and push
git config user.email "dokploy@act360.ca"
git config user.name "Dokploy Auto-SSH"
git add "$SSH_CONFIG_FILE"

if git diff --cached --quiet; then
    echo "register-ssh: no changes to commit"
    exit 0
fi

git commit -m "Auto-register SSH config for ${SITE_NAME}" >/dev/null 2>&1
git push origin HEAD 2>/dev/null
if [ $? -eq 0 ]; then
    echo "register-ssh: pushed config for ${SITE_NAME} successfully"
else
    echo "register-ssh: failed to push (possible conflict, will retry next boot)"
fi
