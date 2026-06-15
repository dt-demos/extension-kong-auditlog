# Kong Konnect Audit Log Extension

A **Dynatrace Extension 2.0** that bundles an OpenPipeline configuration and dashboard for monitoring Kong Konnect audit logs.

## What It Does

Kong Konnect can stream audit logs to Dynatrace via webhook (`/api/v2/logs/ingest`). This extension:

1. **OpenPipeline source** — routes incoming logs from the extension source to the dedicated pipeline
2. **OpenPipeline pipeline** — parses Kong's JSON audit log format, extracting fields for authentication, authorization, and access events
3. **Dashboard** — visualizes audit activity: event counts, user activity, security events, and failed operations

## Project Structure

```
extension-kong-auditlog/
├── extension/                          # Extension 2.0 package source
│   ├── extension.yaml                  # Extension manifest
│   ├── documents/
│   │   └── overview.dashboard.json     # Kong Audit Logs dashboard
│   └── openpipeline/
│       ├── logs.pipeline.json          # Log parsing pipeline (5 processors)
│       └── logs.source.json            # Log source routing config
└── README.md
```

## Developer Setup

### Prerequisites

- Dynatrace environment (1.333+)
- [Dynatrace Extensions VS Code plugin](https://marketplace.visualstudio.com/items?itemName=DynatracePlatformExtensions.dynatrace-extensions)
- Kong Konnect configured to push audit logs to your Dynatrace tenant's log ingest endpoint

### 1. Install the Dynatrace Extensions VS Code Plugin

Install the [Dynatrace Extensions](https://docs.dynatrace.com/docs/ingest-from/extensions/develop-your-extensions/addon-for-vscode) plugin from the VS Code marketplace. This plugin handles building, signing, and uploading Extension 2.0 packages.

### 2. Create a Classic API Token

In your Dynatrace tenant, create a classic API token using the **Extension Development** template:

1. Go to **Settings → Access tokens → Generate new token**
2. Select the **Extension Development** token template (this pre-selects all required scopes)
3. Copy the generated token — you will need it in the next step

### 3. Configure the VS Code Plugin

Connect the plugin to your tenant:

1. Open the VS Code Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`)
2. Run **Dynatrace Extension: Focus on Environments View**
3. Enter your environment URL, e.g. `https://MY-TENANT.live.dynatrace.com`
4. Enter the classic API token from step 2

### 4. Generate a Signing Certificate

Extension 2.0 packages must be signed before upload. Generate a self-signed certificate:

1. Open the Command Palette
2. Run **Dynatrace Extension: Generate certificate**
3. The plugin creates a key pair and saves it locally

### 5. Note the Certificate Path

You need the path to the generated `ca.pem` file:

1. Open **VS Code Settings**
2. Navigate to **Extensions --> Dynatrace Extensions --> Certificates**
3. In the **Certificates Path** make a note of the directory path

The `ca.pem` file is in that directory.  You need that for the next step.

### 6. Upload the CA Certificate to Dynatrace

Dynatrace must trust your signing certificate to accept the extension:

1. In your Dynatrace tenant, go to **Settings → Credentials vault → Add new credentials**
2. Set **Credentials type** to **Public certificate**
3. Upload the `ca.pem` file from the path found in step 5
4. Check **Extension validation** — this registers the cert for verifying extension signatures
5. Save

Once this is done, extensions signed with your local key will be accepted by your tenant.

## Building and Deploying

### Using the VS Code Extension (Recommended)

The `.vscode/settings.json` is already configured with the correct schemas. With the Dynatrace Extensions VS Code plugin:

1. Open this workspace in VS Code
2. Run **Dynatrace Extension: Build** command to create a signed ZIP file.  This increase the version number too and put the ZIP file into the `dist` folder.  
3. The **build** command will also prompt for uploading the ZIP.  Alternatively, use Run **Dynatrace Extension: Upload** command to deploy to your tenant

## Kong Konnect Configuration

In Kong Konnect, configure an audit log webhook to POST to:

```
https://<your-tenant>.live.dynatrace.com/api/v2/logs/ingest
```

With headers:
```
Authorization: Api-Token <your-dt-api-token>
Content-Type: application/json
```

The API token needs the **Ingest logs** (`logs.ingest`) scope.

## Resources

- [Dynatrace Extensions 2.0 Documentation](https://www.dynatrace.com/support/help/extend-dynatrace/extensions20)
- [OpenPipeline Documentation](https://www.dynatrace.com/support/help/platform/opentelemetry/openpipeline)
- [Kong Konnect Audit Logs](https://docs.konghq.com/konnect/org-management/audit-logging/)
