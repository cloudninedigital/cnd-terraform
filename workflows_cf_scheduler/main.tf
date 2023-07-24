# Used to retrieve project_number later
data "google_project" "project" {
  provider = google-beta
  project_id = var.project
}

# Enable Pub/Sub API
resource "google_project_service" "pubsub" {
  provider           = google-beta
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}

# Enable Workflows API
resource "google_project_service" "workflows" {
  provider           = google-beta
  service            = "workflows.googleapis.com"
  disable_on_destroy = false
}



# Create a service account for Eventarc trigger and Workflows
resource "google_service_account" "scheduler_workflows_service_account" {
  provider     = google-beta
  account_id   = "scheduler-workflows-sa"
  display_name = "Eventarc Workflows Service Account"
}

# Grant the logWriter role to the service account
resource "google_project_iam_binding" "project_binding_eventarc" {
  provider = google-beta
  project  = data.google_project.project.id
  role     = "roles/logging.logWriter"

  members = ["serviceAccount:${google_service_account.scheduler_workflows_service_account.email}"]

  depends_on = [google_service_account.scheduler_workflows_service_account]
}

# Grant the workflows.invoker role to the service account
resource "google_project_iam_binding" "project_binding_workflows" {
  provider = google-beta
  project  = data.google_project.project.id
  role     = "roles/workflows.invoker"

  members = ["serviceAccount:${google_service_account.scheduler_workflows_service_account.email}"]

  depends_on = [google_service_account.scheduler_workflows_service_account]
}

# Grant cloud functions and cloud run invoker role
resource "google_project_iam_binding" "cloud_functions_invoker_binding" {
  provider = google-beta
  project  = data.google_project.project.id
  role     = "roles/cloudfunctions.invoker"

  members = ["serviceAccount:${google_service_account.scheduler_workflows_service_account.email}"]

  depends_on = [google_service_account.scheduler_workflows_service_account]
}

resource "google_project_iam_binding" "cloud_run_invoker_binding" {
  provider = google-beta
  project  = data.google_project.project.id
  role     = "roles/run.invoker"

  members = ["serviceAccount:${google_service_account.scheduler_workflows_service_account.email}"]

  depends_on = [google_service_account.scheduler_workflows_service_account]
}


# Define and deploy a workflow
resource "google_workflows_workflow" "workflows_instance" {
  name            = var.name
  provider        = google-beta
  region          = var.region
  description     = var.description
  service_account = google_service_account.scheduler_workflows_service_account.email
  # Imported main workflow template file
  source_contents = templatefile("modules/workflows_cf_scheduler/workflow_templates/${var.workflow_template_file}")

  depends_on = [
    google_project_service.workflows,
    google_service_account.eventarc_workflows_service_account
  ]
}

resource "google_storage_bucket" "workflows_trigger_bucket" {
  name          = var.bucket_name
  location      = var.region
  storage_class = "STANDARD"
  versioning {
    enabled = false
  }
}

resource "google_cloud_scheduler_job" "workflow" {
  project          = var.project
  name             = "${var.name}_scheduler"
  description      = "Cloud Scheduler for Workflow Job ${var.name}"
  schedule         = var.cron_schedule
  region           = var.region

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.workflow_instance.id}/executions"
    body = base64encode(
      jsonencode({
        "argument" : local.cloud_scheduler_args,
        "callLogLevel" : "CALL_LOG_LEVEL_UNSPECIFIED"
        }
    ))

    oauth_token {
      service_account_email = google_service_account.eventarc_workflows_service_account.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

}
