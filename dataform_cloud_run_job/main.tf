## A Cloud Run job that compiles a Dataform repository and runs some of its tags.
##
## No image to build: runner.py (standard library only) is passed to `python3 -c`
## on a stock Python image. Compilation vars can come from the environment at run
## time (var.vars_from_env), so a workflow execution can set e.g. CLIENT_ID and
## the same job runs the tags for that client.

locals {
  dataform_project = var.dataform_project != "" ? var.dataform_project : var.project
  dataform_region  = var.dataform_region != "" ? var.dataform_region : var.region

  runner_environment = {
    DATAFORM_PROJECT                 = local.dataform_project
    DATAFORM_REGION                  = local.dataform_region
    DATAFORM_REPOSITORY              = var.repository
    DATAFORM_GIT_COMMITISH           = var.git_commitish
    DATAFORM_TAGS                    = join(",", var.tags)
    DATAFORM_VARS                    = jsonencode(var.vars)
    DATAFORM_VARS_FROM_ENV           = jsonencode(var.vars_from_env)
    DATAFORM_CODE_COMPILATION_CONFIG = jsonencode(var.code_compilation_config)
    DATAFORM_INCLUDE_DEPENDENCIES    = tostring(var.include_dependencies)
    DATAFORM_INCLUDE_DEPENDENTS      = tostring(var.include_dependents)
    DATAFORM_FULL_REFRESH            = tostring(var.full_refresh)
    DATAFORM_SERVICE_ACCOUNT         = local.invocation_service_account
  }

  # Dataform no longer runs invocations as its default service agent (strict
  # act-as mode), so without a given account the module creates one.
  create_execution_account = var.invocation_service_account == ""
  execution_account_base   = replace("df-${var.name}", "_", "-")
  execution_account_id     = length(local.execution_account_base) <= 30 ? local.execution_account_base : "${substr(local.execution_account_base, 0, 24)}${substr(md5(local.execution_account_base), 0, 6)}"
  invocation_service_account = (
    local.create_execution_account
    ? google_service_account.execution[0].email
    : var.invocation_service_account
  )
  bigquery_project       = var.bigquery_project != "" ? var.bigquery_project : local.dataform_project
  dataform_service_agent = "service-${data.google_project.dataform.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

data "google_project" "dataform" {
  project_id = local.dataform_project
}

module "job" {
  source = "../cloud_run_job"

  project = var.project
  name    = var.name
  region  = var.region
  image   = var.image
  command = ["python3", "-c", file("${path.module}/runner.py")]

  environment_variables = merge(local.runner_environment, var.environment_variables)

  task_count            = 1
  parallelism           = 1
  max_retries           = var.max_retries
  timeout_seconds       = var.timeout_seconds
  cpu                   = var.cpu
  memory                = var.memory
  labels                = var.labels
  instantiate_scheduler = var.instantiate_scheduler
  schedule              = var.schedule
  alert_on_failure      = var.alert_on_failure
  alert_email_addresses = var.alert_email_addresses
}

# Compile and invoke in the (possibly other) project that holds the repository.
resource "google_project_iam_member" "dataform_editor" {
  project = local.dataform_project
  role    = "roles/dataform.editor"
  member  = "serviceAccount:${module.job.executor_service_account_email}"
}

## The account the Dataform invocation runs as (the "effective service account").

# Created only when var.invocation_service_account is empty. A given account is
# used as is: its BigQuery access and the Dataform service agent's grants on it
# are assumed to be in place already.
resource "google_service_account" "execution" {
  count        = local.create_execution_account ? 1 : 0
  project      = local.dataform_project
  account_id   = local.execution_account_id
  display_name = "Dataform execution account for ${var.name}"
}

resource "google_project_iam_member" "execution_roles" {
  for_each = local.create_execution_account ? toset(var.execution_roles) : toset([])
  project  = local.bigquery_project
  role     = each.value
  member   = "serviceAccount:${google_service_account.execution[0].email}"
}

# Dataform's service agent impersonates the execution account to run the SQL.
# The agent exists once the project has a Dataform repository.
resource "google_service_account_iam_member" "dataform_agent_on_execution" {
  for_each           = local.create_execution_account ? toset(["roles/iam.serviceAccountTokenCreator", "roles/iam.serviceAccountUser"]) : toset([])
  service_account_id = google_service_account.execution[0].name
  role               = each.value
  member             = "serviceAccount:${local.dataform_service_agent}"
}

# Strict act-as: whoever creates the invocation (this job) needs actAs on the
# account it runs as.
resource "google_service_account_iam_member" "act_as_invocation_account" {
  service_account_id = "projects/${local.dataform_project}/serviceAccounts/${local.invocation_service_account}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.job.executor_service_account_email}"
}
