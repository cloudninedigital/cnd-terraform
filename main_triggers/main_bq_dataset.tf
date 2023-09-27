module "bigquery_some_dataset" {
  source      = "./modules/bq_dataset"
  dataset_id = "some_dataset"
  friendly_name = "Some Dataset"
  description = "Some Dataset"
  region = var.region

  tables = [
    {
      table_id = "some_table"
      friendly_name = "Some Table"
      description = "Some Table"
      schema = file("${path.module}/../project_name/schemas/some_table.json")
    },
    {
      table_id = "some_other_table"
      friendly_name = "Some Other Table"
      description = "Some YET again Table"
      schema = file("${path.module}/../project_name/schemas/some_other_table.json")
    },
  ]
}