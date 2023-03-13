data "google_secret_manager_secret_version" "arbeidsgiveropplysninger_bigquery_secret" {
  secret = var.arbeidsgiveropplysninger_bigquery_secret
}

locals {
    dataprodukt_arbeidsgiveropplysninger_db_credentials = jsondecode(
        data.google_secret_manager_secret_version.arbeidsgiveropplysninger_bigquery_secret
    )
}