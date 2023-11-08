output "table_ids" {
  value = {
    for k, table in google_bigquery_table.tables: k => table.table_id
  }
}

output table_definitions {
  value = {
  for k, table in var.tables: "${var.dataset_id}_${k}" => {dataset = var.dataset_id, table = table}}
}

output dataset_id {
  value = var.dataset_id
}