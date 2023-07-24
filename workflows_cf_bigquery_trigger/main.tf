# Used to retrieve project_number later
data "google_project" "project" {
  provider = google-beta
  project_id = var.project
}

# Enable Eventarc API
resource "google_project_service" "eventarc" {
  provider           = google-beta
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
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

# If you enabled the Pub/Sub service account on or before April 8, 2021, grant the iam.serviceAccountTokenCreator role to the Pub/Sub service account
resource "google_project_iam_binding" "token-creator-iam" {
  provider = google-beta
  project  = data.google_project.project.id
  role     = "roles/iam.serviceAccountTokenCreator"

  members    = ["serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"]
  depends_on = [google_project_service.pubsub]
}



# Create a service account for Eventarc trigger and Workflows
resource "google_service_account" "eventarc_workflows_service_account" {
  provider     = google-beta
  account_id   = "eventarc-workflows-sa"
  display_name = "Eventarc Workflows Service Account"
}

# Grant the logWriter role to the service account
resource "google_project_iam_binding" "project_binding_eventarc" {
  provider = google-beta
  project  = data.google_project.project.id
  role     = "roles/logging.logWriter"

  members = ["serviceAccount:${google_service_account.eventarc_workflows_service_account.email}"]

  depends_on = [google_service_account.eventarc_workflows_service_account]
}

# Grant the workflows.invoker role to the service account
resource "google_project_iam_binding" "project_binding_workflows" {
  provider = google-beta
  project  = data.google_project.project.id
  role     = "roles/workflows.invoker"

  members = ["serviceAccount:${google_service_account.eventarc_workflows_service_account.email}"]

  depends_on = [google_service_account.eventarc_workflows_service_account]
}


# Grant the eventarc.eventReceiver role to the service account
resource "google_project_iam_binding" "eventarc_receiver_binding" {
  provider = google-beta
  project  = data.google_project.project.id
  role     = "roles/eventarc.eventReceiver"

  members = ["serviceAccount:${google_service_account.eventarc_workflows_service_account.email}"]

  depends_on = [google_service_account.eventarc_workflows_service_account]
}

# Grant cloud functions and cloud run invoker role
resource "google_project_iam_binding" "cloud_functions_invoker_binding" {
  provider = google-beta
  project  = data.google_project.project.id
  role     = "roles/cloudfunctions.invoker"

  members = ["serviceAccount:${google_service_account.eventarc_workflows_service_account.email}"]

  depends_on = [google_service_account.eventarc_workflows_service_account]
}

resource "google_project_iam_binding" "cloud_run_invoker_binding" {
  provider = google-beta
  project  = data.google_project.project.id
  role     = "roles/run.invoker"

  members = ["serviceAccount:${google_service_account.eventarc_workflows_service_account.email}"]

  depends_on = [google_service_account.eventarc_workflows_service_account]
}


resource "google_project_iam_binding" "gcs_binding" {
  provider = google-beta
  project  = data.google_project.project.id
  role     = "roles/storage.admin"

  members = ["serviceAccount:${google_service_account.eventarc_workflows_service_account.email}"]
}

# Define and deploy a workflow
resource "google_workflows_workflow" "workflows_instance" {
  name            = var.name
  provider        = google-beta
  region          = var.region
  description     = var.description
  service_account = google_service_account.eventarc_workflows_service_account.email
  # Imported main workflow template file
  source_contents = templatefile("modules/workflows_cf_bigquery_trigger/workflow_templates/${var.workflow_template_file}", var.workflow_template_vars)

  depends_on = [
    google_project_service.workflows,
    google_service_account.eventarc_workflows_service_account
  ]
}

# Create an Eventarc trigger routing GCS events to Workflows
resource "google_eventarc_trigger" "trigger_gbq_tf" {
  name     = "trigger-gbq-workflow-tf"
  provider = google-beta
  location = var.region
  matching_criteria {
    attribute = "type"
    value = "google.cloud.audit.log.v1.written"
  }

  matching_criteria {
    attribute = "serviceName"
    value = "bigquery.googleapis.com"
  }

  matching_criteria {
    attribute = "methodName"
    value = "google.cloud.bigquery.v2.JobService.InsertJob"
  }

  matching_criteria {
    attribute = "resourceName"
    value = "projects/${var.project}/datasets/${var.dataset}/tables/${var.table}"
    operator = "match-path-pattern"
  }

  destination {
    workflow = google_workflows_workflow.workflows_instance.id
  }


  service_account = google_service_account.eventarc_workflows_service_account.email

  depends_on = [google_project_service.pubsub, google_project_service.eventarc,
  google_service_account.eventarc_workflows_service_account]
}
