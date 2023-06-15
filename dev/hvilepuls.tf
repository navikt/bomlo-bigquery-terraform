resource "google_bigquery_dataset" "flex_dataset" {
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