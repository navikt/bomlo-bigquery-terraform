terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.55.0"
    }
  }
  backend "gcs" {
    bucket = "tbd-bigquery-terraform-state-prod"
  }
}

provider "google" {
  project = var.gcp_project["project"]
  region  = var.gcp_project["region"]
}

data "google_project" "project" {}

module "google_storage_bucket" {
  source = "../modules/google-cloud-storage"

  name     = "tbd-bigquery-terraform-state-prod"
  location = var.gcp_project["region"]
}

# Make a workload pool for bomlo-dbt repo
module "google_bigquery_workload_pool" {
  source = "../modules/google-bigquery-workload-pool"

  project_id    = var.gcp_project["project"]
  grants        = ["roles/bigquery.dataEditor", "roles/bigquery.user"]
  repo_full_name = "navikt/bomlo-dbt"
}
