data "google_secret_manager_secret_version" "arbeidsgiveropplysninger_datastream_user_secret" {
  secret_id = "arbeidsgiveropplysninger_datastream_user_secret"
}

locals {
  dataprodukt_arbeidsgiveropplysninger_db_credentials = jsondecode(
    data.google_secret_manager_secret_version.arbeidsgiveropplysninger_datastream_user_secret.secret_data
  )
}
