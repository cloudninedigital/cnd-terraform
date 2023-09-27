output "tables" {
  value = tomap(google_bigquery_table.tables.*.table_id)
}