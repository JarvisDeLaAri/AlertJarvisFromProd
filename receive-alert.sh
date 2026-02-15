#!/bin/bash
# <ALERT_USER>-alert.sh — SSH forced command that posts alerts to JarvisHub
# Runs on: HUB SERVER (where JarvisHub is running)
#
# This script is triggered automatically when <ALERT_USER> SSHes in.
# It parses the SSH command and POSTs to the local JarvisHub API.
#
# SSH authorized_keys entry:
#   command="/usr/local/bin/<ALERT_USER>-alert.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty <PUBLIC_KEY>

MSG="$SSH_ORIGINAL_COMMAND"
if [ -z "$MSG" ]; then
    echo "ERROR: No alert message provided"
    exit 1
fi

# Parse pipe-delimited: source|title|message|priority
IFS='|' read -r SOURCE TITLE MESSAGE PRIORITY <<< "$MSG"
SOURCE="${SOURCE:-prod}"
TITLE="${TITLE:-Prod Alert}"
MESSAGE="${MESSAGE:-No message}"
PRIORITY="${PRIORITY:-normal}"

# HUB_URL: JarvisHub notify endpoint (localhost only)
HUB_URL="http://127.0.0.1:<HUB_PORT>/notify"

RESPONSE=$(curl -s -X POST "$HUB_URL" \
    -H "Content-Type: application/json" \
    -d "{\"source\": \"$SOURCE\", \"title\": \"$TITLE\", \"message\": \"$MESSAGE\", \"priority\": \"$PRIORITY\"}" \
    2>&1)

echo "$RESPONSE"
