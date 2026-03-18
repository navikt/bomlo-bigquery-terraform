# Lag et syntetisk datasett på logg bøtta så de er tilgjengelig rett i BQ
resource "google_logging_linked_dataset" "logg-dataset" {
  link_id     = "logg_dataset"
  bucket      = "projects/${var.gcp_project["project"]}/locations/europe-north1/buckets/europe-north1-tbd-prod-eacd-logs-bucket"
  description = "Syntetisk datasett linket til bøtta som GCP sikkerloggene ligger i. Dataen i tabellene her ligger i GCP logging fortsatt!"
}

# Lag et log view filter for Spleis logger, som vil gi et view i BQ med bare Spleis logs
resource "google_logging_log_view" "spleis-logger" {
  name        = "SpleisLogger"
  bucket      = "projects/${var.gcp_project["project"]}/locations/europe-north1/buckets/europe-north1-tbd-prod-eacd-logs-bucket"
  description = "View med bare sikker logger fra Spleis"

  # This filter determines what rows show up in BigQuery
  filter = "resource.type=\"k8s_container\" AND resource.labels.container_name=\"spleis\""
}

# Gi dbt service konto lov til å spørre i logg datasettet
resource "google_bigquery_dataset_iam_member" "logg-dataset-dbt-sa" {
  dataset_id = google_logging_linked_dataset.logg-dataset.link_id
  role       = "roles/bigquery.dataViewer"
  member     = module.google_bigquery_workload_pool.workpool-sa-email
}
