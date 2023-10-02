resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
  friendly_name = var.friendly_name
  description = var.description
  location = var.region

  default_table_expiration_ms = var.default_table_expiration_ms
  default_partition_expiration_ms = var.default_partition_expiration_ms
}

resource "google_bigquery_table" "tables" {
  for_each = var.tables
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = each.value.table_id
  dynamic time_partitioning {
    for_each = each.value.partition_table ? [each.value] : []
    content {   
    type = each.value.partition_type
    field = each.value.partition_field
    require_partition_filter = each.value.require_partition_filter
    }
  }

  schema = <<EOF
   ${jsonencode(each.value.schema)}
   EOF
}
