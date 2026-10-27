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

## Service accounts

Two accounts are involved:

- **The job's account** (from `cloud_run_job`) calls the Dataform API. It gets
  `roles/dataform.editor` on the Dataform project, and `roles/iam.serviceAccountUser`
  on the execution account, which strict act-as mode requires to create an invocation.
- **The execution account** is what Dataform runs the SQL as. Under strict act-as,
  Dataform's default service agent can no longer run invocations, so:
  - `invocation_service_account` set: that account is used as is. Its BigQuery
    access and the Dataform service agent's `serviceAccountTokenCreator` /
    `serviceAccountUser` grants on it must already be in place.
  - empty (default): the module creates `df-<name>` with `execution_roles`
    (`bigquery.dataEditor` + `bigquery.jobUser` on `bigquery_project`) and gives
    the Dataform service agent both grants on it. The service agent exists once
    the project has a Dataform repository.

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
