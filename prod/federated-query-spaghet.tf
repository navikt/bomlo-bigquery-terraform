resource "google_service_account" "federated_query_sa" {
  account_id   = "federated-query-sa"
  display_name = "Federated query service konto"
  project      = var.gcp_project["project"]
  description  = "Service konto for å kjøre federated queries mot eksterne datakilder, primært PostgreSQL."
}

# Gi SA'en connection user på Spaghet koblingen
resource "google_bigquery_connection_iam_member" "federated_query_sa_spaghet_connection_user" {
  project       = google_bigquery_connection.spaghet-bigquery-connection.project
  location      = google_bigquery_connection.spaghet-bigquery-connection.location
  connection_id = google_bigquery_connection.spaghet-bigquery-connection.connection_id
  role          = "roles/bigquery.connectionUser"
  member        = "serviceAccount:${google_service_account.federated_query_sa.email}"
}

# Gi SA'en BQ job user
resource "google_project_iam_member" "federated_query_sa_bq_job_user" {
  project = var.gcp_project["project"]
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.federated_query_sa.email}"
}

# Gi SA'en BQ data editor på Spaghet dataset
resource "google_bigquery_dataset_iam_member" "federated_query_sa_spaghet_dataset_editor" {
  dataset_id = google_bigquery_dataset.spaghet_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.federated_query_sa.email}"
}

locals {
  spaghet_connection_full_name = "${var.gcp_project["project"]}.${google_bigquery_connection.spaghet-bigquery-connection.location}.${google_bigquery_connection.spaghet-bigquery-connection.connection_id}"
}

resource "google_bigquery_data_transfer_config" "query_config" {
  display_name           = "vedtaksperiode_venter_fra_spaghet"
  location               = "europe-north1"
  data_source_id         = "scheduled_query"
  schedule               = "every day 01:00"
  destination_dataset_id = google_bigquery_dataset.spaghet_dataset.dataset_id
  service_account_name   = google_service_account.federated_query_sa.email
  params = {
    destination_table_name_template = "public_vedtaksperiode_venter$${run_date}"
    write_disposition               = "WRITE_TRUNCATE"
    query                           = "SELECT * FROM EXTERNAL_QUERY(\"${local.spaghet_connection_full_name}\", \"\"\"${file("./sql/vedtaksperiode_venter.sql")}\"\"\")"
  }
}
