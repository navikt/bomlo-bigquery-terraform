# Lag et syntetisk datasett på logg bøtta så de er tilgjengelig rett i BQ
resource "google_logging_linked_dataset" "logg-dataset" {
  link_id     = "logg_dataset"
  bucket      = "projects/${var.gcp_project["project"]}/locations/europe-north1/buckets/europe-north1-tbd-prod-eacd-logs-bucket"
  description = "Syntetisk datasett linket til bøtta som GCP sikkerloggene ligger i. Dataen i tabellene her ligger i GCP logging fortsatt!"
}
