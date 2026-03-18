
// BQ dataset for å lande logger i i:
resource "google_bigquery_dataset" "log_sink" {
  dataset_id = "log_sink"
  location   = var.gcp_project["region"]
  project    = var.gcp_project["project"]
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
}

// Log sink
resource "google_logging_project_sink" "overstyr_tidslinje_logs" {
  name        = "overstyr_tidslinje_logs"
  description = "En logg sink som sender logger Spleis skriver når den får en overstyr_tidslinje melding til BQ"
  destination = "bigquery.googleapis.com/${google_bigquery_dataset.log_sink.id}"
  filter      = "resource.type=\"k8s_container\" AND resource.labels.container_name=\"spleis\" AND jsonPayload.message: \"gjenkjente OverstyrTidslinjeMessage\""
}
