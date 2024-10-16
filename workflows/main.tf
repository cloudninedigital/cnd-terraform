# START general IAM roles and service account

locals {
  workflows_sa_roles = [
    "roles/logging.logWriter",
    "roles/workflows.invoker",
    "roles/cloudfunctions.invoker",
    "roles/run.invoker",
    "roles/storage.admin",
    "roles/dataform.editor"
  ]
}

# Enable IAM API
resource "google_project_service" "iam" {
  project = var.project
  provider           = google-beta
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

# Cloud scheduler api
resource "google_project_service" "cloudscheduler" {
  project = var.project
  provider           = google-beta
  service            = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}


# Create a service account for Eventarc trigger and Workflows
resource "google_service_account" "workflows_service_account" {
  project = var.project
  provider     = google-beta
  account_id   = var.service_account_name
  display_name = "Workflows Service Account"

  depends_on = [google_project_service.iam]
}

resource "google_project_iam_member" "roles" {
  for_each = toset(local.workflows_sa_roles)
  project  = var.project
  role     = each.key
  member   = "serviceAccount:${google_service_account.workflows_service_account.email}"
}

resource "google_project_iam_member" "dataform_executor" {
  project  = var.dataform_project
  role     = "roles/dataform.editor"
  member   = "serviceAccount:${google_service_account.workflows_service_account.email}"
}

resource "google_project_iam_member" "token-creator-iam" {
  project    = var.project
  role       = "roles/iam.serviceAccountTokenCreator"
  member     = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  depends_on = [google_project_service.pubsub]
}

# END general IAM roles and service account

# START trigger specific IAM roles

# Grant the eventarc.eventReceiver role to the service account
resource "google_project_iam_member" "eventarc_receiver_binding" {
  count    = var.trigger_type == "bq" || var.trigger_type == "gcs" ? 1 : 0
  provider = google-beta
  project  = var.project
  role     = "roles/eventarc.eventReceiver"

  member = "serviceAccount:${google_service_account.workflows_service_account.email}"

  depends_on = [google_service_account.workflows_service_account]
}

resource "google_project_iam_member" "cloudscheduler_admin_binding" {
  count    = var.trigger_type == "schedule" ? 1 : 0
  provider = google-beta
  project  = var.project
  role     = "roles/cloudscheduler.admin"

  member     = "serviceAccount:${google_service_account.workflows_service_account.email}"
  depends_on = [google_service_account.workflows_service_account]
}

resource "google_project_iam_member" "gcs_binding" {
  count    = var.trigger_type == "gcs" ? 1 : 0
  provider = google-beta
  project  = var.project
  role     = "roles/storage.admin"
  member   = "serviceAccount:${google_service_account.workflows_service_account.email}"
}

# END trigger specific IAM roles

# Used to retrieve project_number later
data "google_project" "project" {
  provider   = google-beta
  project_id = var.project
}

# Enable Eventarc API
resource "google_project_service" "eventarc" {
  project = var.project
  count              = var.trigger_type == "bq" || var.trigger_type == "gcs" ? 1 : 0
  provider           = google-beta
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
}

# Enable Pub/Sub API
resource "google_project_service" "pubsub" {
  project = var.project
  provider           = google-beta
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}

# Enable Workflows API
resource "google_project_service" "workflows" {
  project = var.project
  provider           = google-beta
  service            = "workflows.googleapis.com"
  disable_on_destroy = false
}






# Define and deploy a workflow
resource "google_workflows_workflow" "workflows_instance" {
  name            = var.name
  provider        = google-beta
  region          = var.region
  project = var.project
  description     = var.description
  service_account = google_service_account.workflows_service_account.email
  # Imported main workflow template file
  source_contents = var.workflow_type == "dataform" ? templatefile("modules/workflows/workflow_templates/workflows_dataform_template.tftpl", {
    project        = var.dataform_project,
    region         = var.dataform_region,
    stage          = var.stage,
    dataform_pipelines = var.dataform_pipelines,
    trigger_type   = var.trigger_type
  }):  templatefile("modules/workflows/workflow_templates/workflows_cf_template.tftpl", {
    project        = var.project,
    region         = var.functions_region,
    cloudfunctions = var.cloudfunctions,
    trigger_type   = var.trigger_type
  })

  depends_on = [
    google_project_service.workflows,
    google_service_account.workflows_service_account
  ]
}



### START bq TRIGGER SPECIFIC PART

# Create an Eventarc trigger routing BQ table creation/updat events to Workflows
# Only relevant when trigger type equals 'bq'
resource "google_eventarc_trigger" "trigger_gbq_tf" {
  count    = var.trigger_type == "bq" ? 1 : 0
  name     = replace("${var.name}-trigger", "_", "-")
  project = var.project
  provider = google-beta
  location = "global"
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.audit.log.v1.written"
  }

  matching_criteria {
    attribute = "serviceName"
    value     = "bigquery.googleapis.com"
  }

  matching_criteria {
    attribute = "methodName"
    value     = "google.cloud.bigquery.v2.JobService.InsertJob"
  }

  matching_criteria {
    attribute = "resourceName"
    value     = "projects/${var.project}/datasets/${var.dataset}/tables/${var.table}"
    operator  = "match-path-pattern"
  }

  destination {
    workflow = google_workflows_workflow.workflows_instance.id
  }


  service_account = google_service_account.workflows_service_account.email

  depends_on = [google_project_service.pubsub, google_project_service.eventarc,
    google_service_account.workflows_service_account,
  google_project_iam_member.eventarc_receiver_binding]
}


### END bq TRIGGER SPECIFIC PART

### START gcs TRIGGER SPECIFIC PART

resource "google_storage_bucket" "workflows_trigger_bucket" {
  count         = var.trigger_type == "gcs" ? 1 : 0
  name          = var.bucket_name
  location      = var.region
  storage_class = "STANDARD"
  versioning {
    enabled = false
  }
}

# Create an Eventarc trigger routing GCS events to Workflows
resource "google_eventarc_trigger" "trigger_gcs_tf" {
  project = var.project
  count    = var.trigger_type == "gcs" ? 1 : 0
  name     = replace("${var.name}-trigger", "_", "-")
  provider = google-beta
  location = "global"
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }

  matching_criteria {
    attribute = "bucket"
    value     = google_storage_bucket.workflows_trigger_bucket[0].id
  }

  destination {
    workflow = google_workflows_workflow.workflows_instance.id
  }


  service_account = google_service_account.workflows_service_account.email

  depends_on = [
    google_project_service.pubsub,
    google_project_service.eventarc,
    google_service_account.workflows_service_account
  ]
}


### END gcs TRIGGER SPECIFIC PART

### START schedule TRIGGER SPECIFIC PART
### watch out, cloud scheduler isn't available in europe-west4 (and this won't be clear from the error logs)
resource "google_cloud_scheduler_job" "workflow" {
  count       = var.trigger_type == "schedule" ? 1 : 0
  project     = var.project
  name        = "${var.name}-scheduler"
  description = "Cloud Scheduler for Workflow Job ${var.name}"
  schedule    = var.schedule
  region      = var.region

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.workflows_instance.id}/executions"
    body = base64encode(
      jsonencode({
        "argument" : "{}",
        "callLogLevel" : "CALL_LOG_LEVEL_UNSPECIFIED"
        }
    ))

    oauth_token {
      service_account_email = google_service_account.workflows_service_account.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }

  }
  depends_on = [google_workflows_workflow.workflows_instance,
    google_service_account.workflows_service_account,
    google_project_iam_member.cloudscheduler_admin_binding,
  google_project_service.cloudscheduler]
}

### END schedule TRIGGER SPECIFIC PART

# module "bq_executor_alerting_policy" {
#   source = "../bq_executor_alert_policy"
#   count  = ((var.trigger_type == "bq") && var.alert_on_failure) ? 1 : 0
#   name   = "${var.name}_bq_executor_alert"
#   email_addresses = var.alert_email_addresses
# }

## alerting policy
module "alerting_policy" {
  source = "../alert_policy"
  project = var.project
  count  = ((var.trigger_type != "bq") && var.alert_on_failure) ? 1 : 0
  name   = "${var.name}-alert-policy"
  filter = "resource.type=\"workflows.googleapis.com/Workflow\" severity=ERROR resource.labels.workflow_id=\"${var.name}\""
  email_addresses = var.alert_email_addresses
}

# TODO: figure out how to make this policy unique per workflow (or just decide to deploy separately always)
# module "alerting_policy" {
#   source = "../alert_policy"
#   count  = ((var.workflow_type == "dataform") && var.alert_on_failure) ? 1 : 0
#   name   = "${var.name}-df-alert-policy"
#   filter = "resource.type=\"dataform.googleapis.com/Repository\" severity=ERROR"
#   email_addresses = var.alert_email_addresses
# }