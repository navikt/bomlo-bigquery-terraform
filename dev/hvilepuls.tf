resource "google_bigquery_dataset" "hvilepuls_dataset" {
  dataset_id    = "hvilepuls"
  location      = var.gcp_project["region"]
  friendly_name = "hvilepuls"
  labels        = {}

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }
  access {
    role          = "READER"
    special_group = "projectReaders"
  }
  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }
  timeouts {}
}

resource "google_bigquery_table" "hvilepulse_table" {
  dataset_id = google_bigquery_dataset.hvilepuls_dataset.dataset_id
  table_id   = "hvilepuls_poc"
  schema = jsonencode(
    [
      {
        mode = "NULLABLE"
        name = "dato"
        type = "DATE"
      },
      {
        mode = "NULLABLE"
        name = "verdi"
        type = "INTEGER"
      }
    ]
  )

  deletion_protection = false
}