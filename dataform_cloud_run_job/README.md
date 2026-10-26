# Dataform Cloud Run Job Module

A Cloud Run job that compiles a Dataform repository and runs some of its tags,
then waits for the invocation and fails when any action fails. Built on
`../cloud_run_job`.

There is **no image to build**: `runner.py` (Python standard library only) is
passed to `python3 -c` on a stock Python image (`var.image`, default
`python:3.12-slim`).

Compilation vars can be fixed (`vars`) or read from the environment at run time
(`vars_from_env`). Combined with the `workflows` module's `runtime_env_from_args`,
one job serves every client:

```hcl
module "crj_compliance_monitor" {
  source     = "github.com/cloudninedigital/cnd-terraform//dataform_cloud_run_job?ref=<version>"
  project    = var.project
  name       = "crj-compliance-monitor-${terraform.workspace}"
  region     = "europe-west3"
  repository = "compliance-monitor"
  tags       = ["compliance_monitor_client"]
  vars_from_env = { client_id = "CLIENT_ID" }   # CLIENT_ID set per workflow execution
}
```

The job's service account gets `roles/dataform.editor` on the Dataform project,
plus `roles/iam.serviceAccountUser` on `invocation_service_account` when set.

Run it by hand for one client:

```bash
gcloud run jobs execute <name> --region <region> --update-env-vars CLIENT_ID=acme
```

Or locally, against your own gcloud login:

```bash
DATAFORM_PROJECT=p DATAFORM_REGION=europe-west3 DATAFORM_REPOSITORY=r \
DATAFORM_TAGS=compliance_monitor_client DATAFORM_VARS_FROM_ENV='{"client_id":"CLIENT_ID"}' \
CLIENT_ID=acme python3 runner.py
```
