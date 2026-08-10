# Developer Guide — Building and Releasing

This guide covers how to build, validate, upload, and publish releases using the Makefile. For day-to-day local development you can also use the [VS Code Dynatrace Extensions plugin](https://developer.dynatrace.com/develop/extensions/dynatrace-extensions-vscode/) — but releases must be published via the Makefile.

For end-user installation (pre-signed ZIP), see [INSTALL.md](INSTALL.md).

---

## Prerequisites

| Tool | Required for |
|------|-------------|
| Python 3.10+ | `make build`, `make validate`, `make upload` |
| `zip` (macOS built-in) | `make build` |
| GitHub CLI (`brew install gh`) | `make release` and `make schemas` only |

---

## One-Time Setup

**1. Create the virtual environment**

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install "dt-extensions-sdk[cli]"
```

The Makefile references `.venv/bin/dt-sdk` directly — the venv must be at the project root.

**2. Configure environment variables**

Create `.env` at the project root:

```
DT_TENANT_URL=https://<your-tenant>.live.dynatrace.com/
DT_API_TOKEN=<token-with-extensions:read-and-extensions:write>
```

> Use the `.live.dynatrace.com` domain, not `.apps.dynatrace.com`. The Extensions v2 API is only available on the classic domain.

The Makefile reads `.env` automatically. It is gitignored and never committed.

**3. Generate signing certificates**

```bash
source .venv/bin/activate
dt-sdk gencerts
```

This writes two files to `~/.dynatrace/certificates/`:

| File | Description |
|------|-------------|
| `ca.pem` | Public CA certificate — upload to Dynatrace and attach to GitHub Releases |
| `developer.pem` | Private signing key — never share or commit |

**4. Upload the CA certificate to your tenant**

Dynatrace uses this to verify the extension signature before allowing upload. Do this once per tenant.

In Dynatrace: **Settings → Credential Vault → New credential**

| Field | Value |
|-------|-------|
| Credential type | Public certificate |
| Credential scope | Extension validation |
| Certificate file | `~/.dynatrace/certificates/ca.pem` |

Once uploaded, all future versions signed with the same key are trusted automatically.

---

## Build and Upload Workflow

Dynatrace requires a unique version for every upload — including `make validate`. Always bump the version first.

**1. Bump the version**

Edit `extension/extension.yaml`:

```yaml
version: 1.1.2   # increment patch, minor, or major as appropriate
```

See [Versioning](#versioning) for guidance on which to increment.

**2. Build**

```bash
make build
```

Zips the extension and signs it with `~/.dynatrace/certificates/developer.pem` → `dist/`. Aborts with a clear error if the current version already exists in `dist/`.

**3. Validate and upload**

```bash
make validate   # validate against tenant without uploading
make upload     # upload — prints activation link on success
```

**4. Activate**

After upload the extension is registered but not yet active. Follow the link printed by `make upload` to open the Extensions Manager, then activate the new version.

---

## Publishing a GitHub Release

Requires the [GitHub CLI](https://cli.github.com) (`brew install gh`).

Commit all changes first — `make release` tags the current HEAD, so the tag should point to a commit that includes everything in this release (content changes and the version bump):

```bash
git add extension/extension.yaml extension/openpipeline/ extension/documents/
git commit -m "bump version to 1.1.2"
git push
```

Add any other changed files (e.g. `DEVELOP.md`, `Makefile`, `README.md`) to the same commit or a prior one before running `make release`.

Then create the release:

```bash
make release
```

Runs `gh release create v<version>`, attaches the signed ZIP and `ca.pem`, and uses `INSTALL.md` as the release notes. `CA_PEM` defaults to `~/.dynatrace/certificates/ca.pem` — override only if your cert is elsewhere:

```bash
make release CA_PEM=/path/to/ca.pem
```

> `ca.pem` is the public CA certificate — no private key, safe to distribute. End users upload it to their tenant once and can install all future versions signed with the same key.

---

## Certificate Rotation

Only needed when setting up on a new machine or when your CA certificate expires.

```bash
source .venv/bin/activate
dt-sdk gencerts
```

Output goes to `~/.dynatrace/certificates/`. Then repeat [step 4](#4-upload-the-ca-certificate-to-your-tenant) to upload the new `ca.pem` to your tenant.

> **If you have already published releases:** end users have the old `ca.pem` in their Credential Vault. They must upload the new one before installing versions signed by the new CA. Avoid rotating unless necessary.

To reuse one CA across multiple extension repos, point each repo's `make release` at the same cert:

```bash
make release CA_PEM=~/.dynatrace/certificates/ca.pem
```

---

## Other Makefile Targets

| Target | Does |
|--------|------|
| `make schemas` | Downloads extension schemas into `.schemas/` for VS Code validation (gitignored) |
| `make clean` | Removes `dist/` |
| `make help` | Lists all targets with current version and ZIP path |

---

## Versioning

Dynatrace allows one active version at a time. Always increment `version:` in `extension/extension.yaml` before uploading.

| Bump | When |
|------|------|
| **patch** | Bug fixes to pipeline processors, dashboard query corrections |
| **minor** | New dashboard tiles, new parsed fields, new processors |
| **major** | Breaking changes to field names or pipeline structure that affect existing dashboards or saved queries |
