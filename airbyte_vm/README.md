# airbyte_vm

Airbyte Open Source (2.x) on a single Compute Engine VM, installed with `abctl`
(kind-based Kubernetes inside Docker). Intended for batch syncs of small/medium
volumes from non-Google marketing sources (Meta, LinkedIn, Microsoft Ads) into
BigQuery. Google Ads / GA4 should use BigQuery Data Transfer Service / the native
GA4 export instead.

## What it creates

| Resource | Notes |
|---|---|
| VPC + subnet (optional) | Private Google Access on |
| Cloud Router + Cloud NAT (optional) | Outbound for source APIs, Docker/abctl downloads |
| Firewall | `35.235.240.0/20` → tcp 22, 8000 on tag `<name>-iap` |
| VM `e2-standard-4`, 100 GB pd-balanced | No public IP, Shielded VM, OS Login |
| Startup script | Installs Docker Engine + abctl, runs `abctl local install` once |
| Service account | `bigquery.dataEditor` on the dataset, `bigquery.jobUser` on the project |
| BigQuery dataset (optional) | |
| Snapshot schedule (optional) | Daily, 7-day retention, on the boot disk |
| IAP IAM | `iap.tunnelResourceAccessor` (+ OS Login) for `iap_members` |

### Permissions needed to apply

With `manage_iam = true` (default): Editor + Project IAM Admin + IAP Policy Admin.
With `manage_iam = false`: Editor is enough; afterwards a project IAM admin runs
`terraform output -raw manual_iam_commands` (project-level grants for IAP access,
OS Login, and the SA's BigQuery Job User / logging / monitoring roles).

No service-account key is created: the Airbyte BigQuery destination uses the
VM's service account via Application Default Credentials when its
*Service Account Key JSON* field is left empty.

## Usage

```hcl
module "airbyte" {
  source        = "github.com/cloudninedigital/cnd-terraform//airbyte_vm"
  project       = var.project
  bq_dataset_id = "airbyte_raw"
  iap_members   = ["group:data-team@example.com"]
}
```

Then:

```bash
terraform apply
# follow install (15–30 min on first boot)
$(terraform output -raw bootstrap_log_command)
# open the UI
$(terraform output -raw iap_tunnel_command)   # → http://localhost:8000
# credentials
gcloud compute ssh airbyte --tunnel-through-iap --command='sudo abctl local credentials'
```

In Airbyte, create a **BigQuery** destination with project = the `project` input,
dataset = `bq_dataset_id`, location = `bq_location`, credentials empty.

## Operations

- **Upgrade Airbyte**: SSH in, `sudo abctl local install --chart-version <new> --insecure-cookies`
  (take a manual snapshot first). Update `airbyte_chart_version` to match.
- **Restore**: create a disk from a snapshot, swap it in as boot disk.
- **Reboot**: the startup script re-runs, skips install and makes sure the
  kind container is running.
- Startup-script changes only take effect on the next boot; install args only
  matter for the first install (marker `/var/lib/airbyte-bootstrap/installed`).

## Inputs

See `variables.tf`. Key ones: `project`, `region`, `zone`, `name`,
`machine_type`, `disk_size_gb`, `create_network`/`network`/`subnetwork`,
`create_nat`, `bq_dataset_id`, `create_dataset`, `iap_members`,
`abctl_version`, `airbyte_chart_version`, `enable_snapshots`, `enable_apis`.
