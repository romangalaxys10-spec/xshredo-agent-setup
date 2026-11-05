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
   - **Provisioning module** `CreateAccount` callback (cleanest) — the
     delivery POST runs on the WHMCS host, so `AI_DELIVER_KEY` never leaves
     the server-side config. **Preferred.**
   - A WHMCS **hook function** on `AfterModuleCreate` that curl's the
     deliver endpoint from the WHMCS host — same security property.
   - Do **not** run the delivery call from inside the guest VM template or
     cloud-init: that would bake `AI_DELIVER_KEY` into the machine image,
     its metadata or its logs, visible to the customer who owns the VM.

---

## Products to create in WHMCS (the ask, 2026-11)

One product group, **"AI Computers"**, monthly billing only — the xShredo
landing sells exactly these three SKUs at these prices:

| Product | WHMCS product name | Monthly | vCPU | RAM | NVMe | Traffic |
|---------|--------------------|---------|------|-----|------|---------|
| AI-8    | `AI-8`             | $19     | 2    | 8 GB  | 80 GB  | 2 TB |
| AI-16   | `AI-16` (featured) | $39     | 4    | 16 GB | 160 GB | 3 TB |
| AI-32   | `AI-32`            | $79     | 8    | 32 GB | 320 GB | 4 TB |

Requirements:

- **Monthly term only** on all three (landing promises "monthly billing,
  cancel anytime" — no quarterly/annual setup needed for now).
- KVM virtualization, Tampa (TPA01/TPA02), NVMe storage — same iron as the
  existing virtual-servers line, just the AI product packaging.
- Template the VMs with the open agent stack (OpenClaw runtime, Open WebUI,
  n8n, Playwright) so the post-provisioning hook has a base to configure.
- **Email policy:** the WHMCS client email must be the same address the
  customer registered with on xshredo.com — the delivery call matches
  clients by email, and unmatched emails fail with a clean 404.
- Send back the three WHMCS product IDs / store URLs once created — they
  become the `providerRef` checkout targets on the xShredo side.

---

## The hook (runs on the WHMCS host, drives the new VM over SSH)

Two steps, both launched from the WHMCS host — the secret stays there:

**Step 1 — configure the VM.** SSH into the freshly provisioned machine
and run the framework bootstrap (`FRAMEWORK` comes from the order: the
customer picks **OpenClaw** or **Hermes** at checkout; if the template
doesn't read it yet, default to `openclaw`):

```bash
ssh root@<new-vm-ip> 'curl -fsSL https://raw.githubusercontent.com/romangalaxys10-spec/xshredo-agent-setup/main/bootstrap.sh \
  FRAMEWORK=openclaw \
  sh'
```

The bootstrap installs Docker + the framework, then **rotates the root
password**.

**Step 2 — register the machine with xShredo.** From the WHMCS host
(after the rotation), POST the new credentials — xShredo stores them
encrypted (AES-256-GCM):

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
- The bootstrap inside the guest never phones home at all — registration
  is done by the WHMCS-host hook (step 2), so no keys or customer data
  ever exist inside the VM image.
- If the registration call fails (xShredo unreachable), the VM is still
  fully usable — the machine can be added to the console manually.

## Pinning

Production should pin the installer to a commit:

```
AGENT_SETUP_BASE=https://raw.githubusercontent.com/romangalaxys10-spec/xshredo-agent-setup/<sha>
```

XShredo announces pin bumps in the usual channel before merging changes.
