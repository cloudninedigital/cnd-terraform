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

resource "google_project_iam_binding" "gcs_binding" {
  provider = google-beta
  project  = data.google_project.project.id
  role     = "roles/storage.admin"

  members = ["serviceAccount:${google_service_account.eventarc_workflows_service_account.email}"]
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


# Define and deploy a workflow
resource "google_workflows_workflow" "workflows_instance" {
  name            = var.name
  provider        = google-beta
  region          = var.region
  description     = var.description
  service_account = google_service_account.eventarc_workflows_service_account.email
  # Imported main workflow template file
  source_contents = templatefile("modules/workflows_cf_bucket_trigger/workflow_templates/${var.workflow_template_file}")

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

# Create an Eventarc trigger routing GCS events to Workflows
resource "google_eventarc_trigger" "trigger_gcs_tf" {
  name     = "trigger-gcs-workflow-tf"
  provider = google-beta
  location = var.region
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }

  matching_criteria {
    attribute = "bucket"
    value     = google_storage_bucket.workflows_trigger_bucket.id
  }

  destination {
    workflow = google_workflows_workflow.workflows_instance.id
  }


  service_account = google_service_account.eventarc_workflows_service_account.email

  depends_on = [google_project_service.pubsub, google_project_service.eventarc,
  google_service_account.eventarc_workflows_service_account]
}