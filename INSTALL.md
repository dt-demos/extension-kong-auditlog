# Kong Konnect Audit Log Extension — Installation Guide

Streams Kong Konnect audit logs into Dynatrace via webhook, enriches them through OpenPipeline, and surfaces them in a pre-built dashboard.

---

## Prerequisites

- Dynatrace SaaS tenant (OpenPipeline must be enabled)
- Kong Konnect account with webhook configuration access
- A Dynatrace API token with `logs.ingest` scope (for the Kong webhook)
- A Dynatrace API token with `extensions:read` and `extensions:write` scopes (for installation)

---

## Step 1 — Download the release assets

From the [GitHub Releases](../../releases) page, download both files:
- `custom_com.dynatrace.extension.kong-auditlog-x.x.x.zip` — the signed extension
- `ca.pem` — the publisher's public CA certificate, attached to each release

## Step 2 — Upload the CA certificate to your tenant *(one-time per environment)*

Dynatrace uses this certificate to verify the extension's signature before allowing upload.

In Dynatrace: **Settings → Credential Vault → New credential**

| Field | Value |
|-------|-------|
| Credential type | Public certificate |
| Credential scope | Extension validation |
| Certificate file | `ca.pem` |

Once uploaded, this certificate covers all future versions of this extension signed with the same key. You do not need to repeat this step when upgrading.

## Step 3 — Upload the extension

In Dynatrace, search for **Extensions** in the app search bar, open the Extensions app, then **Upload extension → select the ZIP file**.

Dynatrace validates the signature against the CA certificate in the Credential Vault and registers the extension.

## Step 4 — Activate the extension

After upload the extension is registered but not yet active. Activate it so the OpenPipeline config and dashboard go live:

In the Extensions app, find **Kong Audit Log Extension → Activate**. If you see a version list, select the version you just uploaded and click **Activate**.

## Step 5 — Configure the OpenPipeline dynamic route

Incoming webhook logs need a dynamic route to direct them into the extension's pipeline.

In Dynatrace: **Settings → OpenPipeline → Logs → Dynamic Routing → Add Dynamic Route**

| Field | Value |
|-------|-------|
| Matching condition | `matchesPhrase(content, "KongInc")` |
| Pipeline | Kong Audit Log Pipeline |

Save the route. Logs matching this condition will now flow through the extension's parsing pipeline.

## Step 6 — Configure the Kong Konnect webhook

In Kong Konnect, create a webhook to forward audit logs to Dynatrace:

| Field | Value |
|-------|-------|
| URL | `https://<your-tenant>.live.dynatrace.com/api/v2/logs/ingest` |
| Header name | `Authorization` |
| Header value | `Api-Token <your-logs.ingest-token>` |

Logs will appear in the **Kong Audit Logs** dashboard within a few minutes of the first webhook event.

---

## Verifying the Installation

After the webhook is configured and events start flowing:

1. In Dynatrace, open the **Extensions app** and confirm the extension status is **Active**
2. Open **Dashboards → Kong Audit Logs** — KPI tiles should show event counts within a few minutes
3. Run a DQL spot-check in **Notebooks**:
   ```
   fetch logs
   | filter log.source == "kong-audit-webhook"
   | sort timestamp desc
   | limit 10
   ```
