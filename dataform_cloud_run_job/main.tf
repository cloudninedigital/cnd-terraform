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
    DATAFORM_SERVICE_ACCOUNT         = var.invocation_service_account
  }
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

# Running an invocation as a custom service account needs actAs on it (strict act-as).
resource "google_service_account_iam_member" "act_as_invocation_account" {
  count              = var.invocation_service_account == "" ? 0 : 1
  service_account_id = "projects/${local.dataform_project}/serviceAccounts/${var.invocation_service_account}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.job.executor_service_account_email}"
}
