# xShredo Agent Setup

Bootstrap scripts that turn a freshly provisioned VM into a **Shredy-ready
AI Computer**: Docker + the chosen agent framework (OpenClaw or Hermes) +
the bridge workspace, then (optionally) registration into the customer's
xShredo console.

Used by ARPHost's WHMCS auto-delivery — see
[`docs/BARRY-WHMCS-INTEGRATION.md`](docs/BARRY-WHMCS-INTEGRATION.md).

## Quick start (on the new VM, as root)

```bash
curl -fsSL https://raw.githubusercontent.com/romangalaxys10-spec/xshredo-agent-setup/main/bootstrap.sh | FRAMEWORK=openclaw bash
```

Environment:

| Var | Values | Default | Purpose |
|---|---|---|---|
| `FRAMEWORK` | `openclaw` \| `hermes` | `openclaw` | which agent runtime to install |
| `XSHREDO_DELIVER_URL` | URL | — | if set, the VM is registered into the customer's console after setup |
| `XSHREDO_DELIVER_KEY` | secret | — | shared secret for the deliver API (same value as the xShredo VPS `AI_DELIVER_KEY`) |
| `CLIENT_EMAIL` | email | — | customer email, used by the registration call |

## Layout

```
bootstrap.sh          # entrypoint: docker + framework + registration
openclaw/install.sh   # OpenClaw runtime install (docker)
hermes/install.sh     # Hermes agent runtime install (docker)
docs/                 # Barry's WHMCS auto-delivery integration guide
```

## Frameworks

- **OpenClaw** — the open-source agent runtime (also what Otto One ships).
- **Hermes** — the Hermes agent framework; same console, same bridges,
  different harness.

Both get the same shell around them: Docker, the bridge workspace
(`~/xshredo-ai`), WhatsApp/Telegram pairing hooks and nightly-backup
integration.
