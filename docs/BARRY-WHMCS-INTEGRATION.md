# Barry's Guide — WHMCS Auto-Delivery → Shredy-Ready AI Computer

How to wire ARPHost's WHMCS auto-provisioning so that every AI Computer
order lands **pre-configured** in the customer's xShredo console — with the
framework (OpenClaw or Hermes) the customer picked at order time.

---

## The flow, end to end

```
1. Customer orders on xshredo.com (AI-8 / AI-16 / AI-32, picks framework)
2. Order mirrors to WHMCS → WHMCS provisions the VM (existing flow)
3. WHMCS post-provisioning hook runs on the new VM:
     bootstrap.sh  +  registration call to xshredo
4. Customer opens https://xshredo.com/ai-computer/console
   → machine is already there: framework, pairing, software manifest
5. Customer pairs WhatsApp/Telegram, adds stacks, and Shredy goes to work
```

xShredo never touches step 3 — it's Barry's side. Everything needed is in
this repo (`xshredo-agent-setup`).

---

## One-time setup (Barry)

1. Get the shared delivery secret from xShredo (`AI_DELIVER_KEY`) — it lives
   in the xShredo VPS `.env`; keep it in WHMCS's stored config, never in git.
2. Decide where the hook lives. WHMCS options:
   - **Provisioning module** `CreateAccount` callback (cleanest), or
   - a `post-provisioning` shell step in the VM template / cloud-init that
     curl's the bootstrap.

---

## The hook (runs on the new VM after provisioning)

```bash
curl -fsSL https://raw.githubusercontent.com/romangalaxys10-spec/xshredo-agent-setup/main/bootstrap.sh \
  FRAMEWORK=openclaw \
  XSHREDO_DELIVER_URL=https://xshredo.com/api/ai-computer/deliver \
  XSHREDO_DELIVER_KEY=<AI_DELIVER_KEY> \
  CLIENT_EMAIL=<customer email from the order> \
  sh
```

- `FRAMEWORK` comes from the order: the customer picks **OpenClaw** or
  **Hermes** at checkout (xShredo stores it on the order/machine record).
  If your template doesn't read it yet, default to `openclaw`.
- The bootstrap installs Docker + the framework, then **rotates the root
  password** and registers the machine (host + new credential, encrypted)
  into the customer's xShredo console via:

```
POST https://xshredo.com/api/ai-computer/deliver
X-Deliver-Key: <AI_DELIVER_KEY>
{ "clientEmail", "label", "host", "sshPort", "sshUser", "sshPass", "framework" }
```

Response `{"ok":true,"id":"…"}` — that's it. The customer's console shows
the machine immediately.

---

## Notes & guarantees

- The deliver endpoint is key-gated (401 without the right
  `X-Deliver-Key`); credentials are stored encrypted (AES-256-GCM) and are
  never displayed again — rotation is the customer's lever, via support.
- Framework switching **after** delivery is a customer-side console action;
  the manifest applies on the next provisioning sync. No WHMCS involvement.
- The bootstrap never phones home except to the xShredo deliver URL above.
- If the registration call fails (xShredo unreachable), the VM is still
  fully usable — the machine can be added to the console manually.

## Pinning

Production should pin the installer to a commit:

```
AGENT_SETUP_BASE=https://raw.githubusercontent.com/romangalaxys10-spec/xshredo-agent-setup/<sha>
```

XShredo announces pin bumps in the usual channel before merging changes.
