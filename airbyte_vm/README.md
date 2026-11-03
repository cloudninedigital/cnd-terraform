# airbyte_vm

Airbyte Open Source (2.x) on a single private Compute Engine VM, installed with
[`abctl`](https://docs.airbyte.com/using-airbyte/getting-started/oss-quickstart)
(kind-based Kubernetes inside Docker). Meant for **batch syncs of small/medium
volumes from non-Google marketing sources** (Meta, LinkedIn, Microsoft Ads, …)
into BigQuery. Google Ads / GA4 should go through the BigQuery Data Transfer
Service / the native GA4 export instead.

Why a VM + abctl (and not Helm on GKE or docker-compose): batch workloads, low
volumes, one thing to hand over. docker-compose is no longer supported by Airbyte.

First used for Exact (`ext-exact-marketingdatatobq`, Nov 2026).

## What it creates

| Resource | Notes |
|---|---|
| VPC + subnet (optional, `create_network`) | Private Google Access on |
| Cloud Router + Cloud NAT (optional, `create_nat`) | Outbound for source APIs, Docker/abctl downloads |
| Firewall `<name>-allow-iap` | `35.235.240.0/20` → tcp 22, 8000 on tag `<name>-iap` |
| VM `e2-standard-4`, 100 GB pd-balanced | No public IP, Shielded VM, OS Login, deletion protection |
| Startup script | Installs Docker Engine + abctl, runs `abctl local install` once (idempotent on reboot) |
| Service account `<name>-vm` | `bigquery.dataEditor` on the dataset; `bigquery.jobUser`, `logging.logWriter`, `monitoring.metricWriter` on the project. **No key.** |
| BigQuery dataset (optional, `create_dataset`) | |
| Snapshot schedule (optional, `enable_snapshots`) | Daily, 7-day retention, on the boot disk |
| IAP tunnel + OS Login IAM | For `iap_members` |
| Web UI (optional, `enable_web_ui`) | Cloud Run nginx proxy with IAP (Google login) on its `run.app` URL → Direct VPC egress → VM:8000 |

The Airbyte BigQuery destination uses the VM's service account through
Application Default Credentials: leave **Service Account Key JSON empty**.

## Usage

Deploy once per client, in the template's **shared** workspace
(`terraform/shared`, `sh deploy.sh`), not per dev/stg/prd stage.

```hcl
module "airbyte_vm" {
  source  = "github.com/cloudninedigital/cnd-terraform//airbyte_vm?ref=<tag>"
  project = var.project
  region  = var.region
  zone    = var.zone

  bq_dataset_id = "airbyte_raw"
  iap_members   = ["user:you@cloudninedigital.nl", "user:contact@client.com"]
  enable_web_ui = true
}
```

Requires Google provider **>= 7.46** (`iap_enabled` on Cloud Run).

### Permissions needed to apply

| `manage_iam` | Deployer needs |
|---|---|
| `true` (default) | Editor + Project IAM Admin + IAP Policy Admin |
| `false` | Editor; a project IAM admin then runs `terraform output -raw manual_iam_commands` (and `manual_web_ui_iam_commands`) |

`grant_sa_user` (default `true`) grants `iap_members` Service Account User on
the VM's SA, needed for OS Login SSH by non-Editors. It requires
`iam.serviceAccounts.setIamPolicy`, which Project IAM Admin does **not** have.
Set `false` when the deployer (and SSH users) are Editors.

## First deploy: runbook

1. `terraform apply`, then follow the install (10–30 min):
   `$(terraform output -raw bootstrap_log_command)`, done when you see
   `airbyte bootstrap done`.
2. Login password: `gcloud compute ssh <name> --tunnel-through-iap ... --command='sudo abctl local credentials'`.
3. **Web UI only: one-time OAuth setup (manual, ~10 min).** Google no longer
   offers an API for OAuth brands/clients, so Terraform can't do this:
   1. *Google Auth Platform* (APIs & Services → OAuth consent screen) → Get started.
      Audience **External** if any user is outside the project's organization
      (always the case for consultants, and for **projects without an organization**).
   2. Stay in **Testing** and add every user under *Audience → Test users*.
      Publishing needs a homepage + privacy policy URL and isn't worth it.
   3. *Clients → Create client* → Web application. Add redirect URI
      `https://iap.googleapis.com/v1/oauth/clientIds/<CLIENT_ID>:handleRedirect`.
   4. *Security → Identity-Aware Proxy* (`/security/iap`) → the `<name>-ui`
      Cloud Run service → Settings → **Custom OAuth** → client ID + secret.

   Without this you get `Empty Google Account OAuth client ID(s)/secret(s).`
4. Open `terraform output -raw web_ui_url`, do Airbyte's setup screen and log in.
5. Create the BigQuery destination (project, dataset, location, credentials empty,
   a loading method that needs no GCS bucket) and **Test** it.
6. Pin `abctl_version` / `airbyte_chart_version` to what was installed.

Fallback/admin access without the web UI:
`$(terraform output -raw iap_tunnel_command)` → http://localhost:8000.

## Access model

- **Who can reach Airbyte** is decided by Google IAM (IAP), per person:
  `iap_members` (+ OAuth test users while the consent screen is in Testing).
  Removing someone there removes their access, even if they know the password.
- **Airbyte OSS has a single login** (email + password) per instance; separate
  users/RBAC/SSO are paid Airbyte editions. Share it via a password manager or
  Secret Manager. At handover, switch it to a client-owned address/password
  (`sudo abctl local credentials --help`).

## How the web UI proxy works (and why)

nginx on Cloud Run forwards to `http://<vm-ip>:8000` with:

- `Host: localhost`: abctl's ingress was installed for localhost.
- **Origin rewrite**: Airbyte's API returns an empty **403 on POSTs** whose
  `Origin` isn't the install URL. The proxy rewrites `Origin` to
  `http://localhost:8000` **only** when it equals the proxy's own
  `https://$host`. Other origins pass through unchanged, so Airbyte keeps
  rejecting cross-site requests. This keeps working behind a custom domain/LB.

A custom domain / HTTPS load balancer can be put in front of the Cloud Run
service later without changes to the VM.

## Operations

- **Upgrade Airbyte**: take a manual snapshot, SSH in,
  `sudo abctl local install --chart-version <new> --insecure-cookies`, then
  update `airbyte_chart_version`.
- **Restore**: create a disk from a snapshot and swap it in as boot disk.
- **Reboot**: the startup script re-runs, skips the install (marker
  `/var/lib/airbyte-bootstrap/installed`) and makes sure the kind container runs.
- Startup-script changes only take effect on the next boot
  (`gcloud compute instances reset <name>`); install args only matter for the
  first install.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `An argument named "iap_enabled" is not expected here` | Google provider too old; use >= 7.46 in the calling root. |
| `/var/log/airbyte-bootstrap.log` missing; serial log shows `/usr/bin/env: 'bash\r'` | Module checked out with CRLF on Windows. Fixed in this module (CRs stripped + `.gitattributes`); for older versions re-init and `reset` the VM. |
| `Empty Google Account OAuth client ID(s)/secret(s).` | OAuth setup (runbook step 3) not done. |
| UI loads but buttons do nothing; POST `/api/v1/...` returns empty 403 | Origin check; requires the proxy Origin rewrite (this version). |
| `run.invoker` for the IAP service agent fails (agent doesn't exist) | `gcloud beta services identity create --service=iap.googleapis.com --project=<project>`, apply again. |
| SSH `Remote side unexpectedly closed` right after a reset | VM still booting; retry after a minute. |

## Inputs

See `variables.tf`. Key ones: `project`, `region`, `zone`, `name`,
`machine_type`, `disk_size_gb`, `create_network` / `network` / `subnetwork`,
`create_nat`, `bq_dataset_id`, `create_dataset`, `bq_location`, `iap_members`,
`manage_iam`, `grant_sa_user`, `grant_os_login`, `enable_web_ui`,
`web_ui_members`, `abctl_version`, `airbyte_chart_version`, `enable_snapshots`,
`enable_apis`.
