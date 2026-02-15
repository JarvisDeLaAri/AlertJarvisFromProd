#!/bin/bash
# alert-jarvis.sh — Send alerts from prod to Jarvis via SSH
# Runs on: PROD SERVER
#
# Usage:
#   alert-jarvis.sh "source" "title" "message" "priority"
#
# Examples:
#   alert-jarvis.sh "service-health" "🚨 Service DOWN" "Caddy is not responding" "urgent"
#   alert-jarvis.sh "ariel" "Message" "hello jarvis" "normal"
#
# Priority levels: urgent, high, normal, low

SOURCE="${1:-prod}"
TITLE="${2:-Alert}"
MESSAGE="${3:-No message}"
PRIORITY="${4:-normal}"

# SSH_USER: restricted user on the hub server (forced command, no shell)
# SSH_KEY: private key for the restricted user
# SSH_HOST: hub server IP/hostname
# SSH_PORT: hub server SSH port

SSH_USER="prodcaller"
SSH_KEY="/root/.ssh/id_prodcaller"
SSH_HOST="<HUB_SERVER_IP>"
SSH_PORT="<HUB_SSH_PORT>"

ssh -i "$SSH_KEY" -p "$SSH_PORT" \
    -o ConnectTimeout=10 \
    -o StrictHostKeyChecking=no \
    -o BatchMode=yes \
    "$SSH_USER@$SSH_HOST" "${SOURCE}|${TITLE}|${MESSAGE}|${PRIORITY}" 2>/dev/null
