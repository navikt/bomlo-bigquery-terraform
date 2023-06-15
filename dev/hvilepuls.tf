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

resource "google_service_account" "styringsinformasjon_bigquery" {
  account_id   = "styringsinformasjon-bigquery"
  description  = "Service Account brukt av Team Hvilepuls for Scheduled Queries."
  display_name = "Hvilepuls Scheduled Query"
}

resource "google_project_iam_member" "styringsinformasjon_data_editor" {
  project = data.google_project.project.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.styringsinformasjon_bigquery.email}"
}

resource "google_project_iam_member" "styringsinformasjon_job_user" {
  project = data.google_project.project.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.styringsinformasjon_bigquery.email}"
}

resource "google_project_iam_member" "styringsinformasjon_data_viewer" {
  project = data.google_project.project.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.styringsinformasjon_bigquery.email}"
}