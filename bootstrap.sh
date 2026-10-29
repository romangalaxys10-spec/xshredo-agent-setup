#!/bin/sh
# xShredo Agent Setup — bootstrap
# Usage (on the freshly provisioned customer VM, as root):
#   curl -fsSL <bootstrap-url> | FRAMEWORK=openclaw bash
#
# Env:
#   FRAMEWORK            openclaw | hermes        (default: openclaw)
#   AGENT_SETUP_BASE     pin the installer source to a commit, e.g.
#                        https://raw.githubusercontent.com/<org>/<repo>/<sha>
#   XSHREDO_DELIVER_URL  https://xshredo.com/api/ai-computer/deliver
#   XSHREDO_DELIVER_KEY  shared secret (xShredo VPS .env: AI_DELIVER_KEY)
#   CLIENT_EMAIL         customer email for console registration
#
# SECURITY NOTES
#   * Docker is installed from get.docker.com (official installer).
#   * When registration vars are set, this script ROTATES the root password
#     and sends the new credential ONCE over HTTPS to the xShredo deliver API,
#     where it is stored encrypted (AES-256-GCM). This is what puts the
#     machine into the customer's console.
#   * Without the registration vars, nothing leaves the machine.
set -e

FRAMEWORK="${FRAMEWORK:-openclaw}"
case "$FRAMEWORK" in
  openclaw|hermes) ;;
  *) echo "ERROR: FRAMEWORK must be 'openclaw' or 'hermes' (got '$FRAMEWORK')"; exit 1;;
esac

if [ "$(id -u)" != "0" ]; then echo "ERROR: run as root"; exit 1; fi

echo ""
echo "  xShredo Agent Setup — framework: $FRAMEWORK"
echo "  --------------------------------------------"

if ! command -v docker >/dev/null 2>&1; then
  echo "→ Installing Docker (official get.docker.com installer)…"
  curl -fsSL https://get.docker.com | sh
  systemctl enable --quiet docker 2>/dev/null || true
fi
echo "→ Docker OK: $(docker --version | cut -d' ' -f3)"

SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd || echo ".")
if [ -f "$SCRIPT_DIR/$FRAMEWORK/install.sh" ]; then
  echo "→ Running $FRAMEWORK installer (local checkout)…"
  sh "$SCRIPT_DIR/$FRAMEWORK/install.sh"
else
  BASE="${AGENT_SETUP_BASE:-https://raw.githubusercontent.com/romangalaxys10-spec/xshredo-agent-setup/main}"
  echo "→ Fetching $FRAMEWORK installer from $BASE…"
  curl -fsSL "$BASE/$FRAMEWORK/install.sh" | sh
fi

# ── optional: register into the customer's console ──────────────────
if [ -n "$XSHREDO_DELIVER_URL" ] && [ -n "$XSHREDO_DELIVER_KEY" ] && [ -n "$CLIENT_EMAIL" ]; then
  echo "→ Registering machine into customer console (rotating root password)…"
  HOST=$(curl -fsS --max-time 5 https://ifconfig.me 2>/dev/null || echo "unknown")
  PASS=$(head -c 18 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 18)
  echo "root:$PASS" | chpasswd
  if curl -fsS -X POST "$XSHREDO_DELIVER_URL" \
    -H "X-Deliver-Key: $XSHREDO_DELIVER_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"clientEmail\":\"$CLIENT_EMAIL\",\"label\":\"AI Computer ($FRAMEWORK)\",\"host\":\"$HOST\",\"sshPort\":22,\"sshUser\":\"root\",\"sshPass\":\"$PASS\",\"framework\":\"$FRAMEWORK\"}" > /dev/null; then
    echo "→ Registered ✓ — the customer's console now shows this machine."
  else
    echo "→ WARN: registration failed. Machine is usable; add it to the console manually."
  fi
fi

echo ""
echo "  Done. Framework '$FRAMEWORK' installed and running."
echo "  Customer console: https://xshredo.com/ai-computer/console"
echo ""
