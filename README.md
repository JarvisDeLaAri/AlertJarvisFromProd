# AlertJarvisFromProd

Secure, zero-credential alert pipeline from a production server to [JarvisHub](https://github.com/JarvisDeLaAri/YourJarvisHub).

## Architecture

```
┌──────────────┐     SSH (forced command)     ┌──────────────┐     HTTP (localhost)     ┌──────────────┐
│  Prod Server │ ──────────────────────────►  │  Hub Server  │ ──────────────────────►  │  JarvisHub   │
│              │    prodcaller user            │              │    POST /notify          │              │
│ alert-       │    (key-only, no shell,      │ prodcaller-  │                          │ Wakes Jarvis │
│ jarvis.sh    │     no forwarding)           │ alert.sh     │                          │ → WhatsApp   │
└──────────────┘                              └──────────────┘                          └──────────────┘
```

## How It Works

1. **Monitoring scripts** on prod detect an issue (service down, rootkit found, suspicious auth, etc.)
2. They call `alert-jarvis.sh` with source, title, message, and priority
3. The script SSHes into the hub server as `prodcaller` — a **locked-down user** with:
   - Forced command via `authorized_keys` (can ONLY run `prodcaller-alert.sh`)
   - No port forwarding, no X11, no agent forwarding, no PTY
   - Key-only authentication
4. `prodcaller-alert.sh` parses the alert and POSTs to [JarvisHub](https://github.com/JarvisDeLaAri/YourJarvisHub) on localhost
5. JarvisHub wakes the AI assistant → forwards alert to WhatsApp

## Security

- **No credentials stored on prod** — only an SSH private key for a user that can do exactly ONE thing
- **No ports opened** — uses existing SSH port, no new attack surface
- **No secrets in transit** — SSH encrypts everything
- **Forced command** — even if the key is compromised, attacker can only post alerts to JarvisHub
- **Prod server IP whitelisted** in fail2ban to prevent accidental lockout

## Files

| File | Where | What |
|------|-------|------|
| `alert-jarvis.sh` | Prod server (`/usr/local/bin/`) | Sends alerts via SSH |
| `prodcaller-alert.sh` | Hub server (`/usr/local/bin/`) | Receives alerts, posts to JarvisHub |

## Setup

### On the Hub Server (where JarvisHub runs)

1. Create the restricted user:
```bash
useradd --system --shell /bin/bash --home-dir /var/lib/prodcaller --create-home prodcaller
```

2. Generate SSH keypair (or generate on prod and copy public key here):
```bash
ssh-keygen -t ed25519 -f /var/lib/prodcaller/.ssh/id_prodcaller -N "" -C "prodcaller"
```

3. Set up authorized_keys with forced command:
```bash
echo 'command="/usr/local/bin/prodcaller-alert.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty <PUBLIC_KEY>' > /var/lib/prodcaller/.ssh/authorized_keys
chmod 700 /var/lib/prodcaller/.ssh
chmod 600 /var/lib/prodcaller/.ssh/authorized_keys
chown -R prodcaller:prodcaller /var/lib/prodcaller
```

4. Add `prodcaller` to SSH AllowUsers:
```bash
# In your sshd hardened config:
AllowUsers root prodcaller
```

5. Install `prodcaller-alert.sh`:
```bash
cp prodcaller-alert.sh /usr/local/bin/
chmod 755 /usr/local/bin/prodcaller-alert.sh
```

6. Edit `prodcaller-alert.sh` — set `HUB_URL` to your JarvisHub port.

7. Whitelist prod server IP in fail2ban (`ignoreip` in jail.local).

### On the Prod Server

1. Copy the private key to `/root/.ssh/id_prodcaller` (chmod 600).

2. Install `alert-jarvis.sh`:
```bash
cp alert-jarvis.sh /usr/local/bin/
chmod 755 /usr/local/bin/alert-jarvis.sh
```

3. Edit `alert-jarvis.sh` — set `SSH_HOST`, `SSH_PORT`, and `SSH_USER`.

4. Test:
```bash
alert-jarvis.sh "test" "🧪 Test" "Hello from prod!" "normal"
```

### Wiring Monitoring Scripts

Call `alert-jarvis.sh` from any monitoring script. Examples:

```bash
# Service health check
if ! systemctl is-active --quiet caddy; then
    alert-jarvis.sh "service-health" "🚨 Service DOWN" "Caddy is not running" "urgent"
fi

# Login notification (PAM)
if [ "$PAM_TYPE" = "open_session" ]; then
    alert-jarvis.sh "ssh-login" "🔐 SSH Login" "User: $PAM_USER from $PAM_RHOST" "high"
fi

# Rootkit detection
OUTPUT=$(rkhunter --check --skip-keypress --report-warnings-only 2>&1)
if [ -n "$OUTPUT" ]; then
    alert-jarvis.sh "rkhunter" "⚠️ rkhunter Warning" "$OUTPUT" "high"
fi
```

## Priority Levels

| Priority | Emoji | When to use |
|----------|-------|-------------|
| `urgent` | 🚨 | Service down, rootkit found, security breach |
| `high` | ❗ | SSH login, auth failures, file integrity changes |
| `normal` | 📬 | Routine alerts, manual messages |
| `low` | 📝 | Info, non-critical updates |

---

Built by Jarvis de la Ari & Ariel @ Bresleveloper AI 🦞


---

[![YouTube](https://img.shields.io/badge/YouTube-BresleveloperAI-red?logo=youtube)](https://www.youtube.com/@BresleveloperAI/videos)

[ישראלי/דובר עברית? כנס ליוטיוב שלי לתכנים נוספים על בינה מלאכותית (לא לשכוח להרשם ♥, פעמון ♥, לייק ♥, ולשלוח לחבר ♥♥♥)](https://www.youtube.com/@BresleveloperAI/videos)
