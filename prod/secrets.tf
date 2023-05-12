data "google_secret_manager_secret_version" "arbeidsgiveropplysninger_datastream_user_secret" {
  secret = "arbeidsgiveropplysninger_datastream_user_secret"
}

data "google_secret_manager_secret_version" "forstegangsbehandling_datastream_user_secret" {
  secret = "forstegangsbehandling_datastream_user_secret"
}

data "google_secret_manager_secret_version" "spaghet_datastream_user_secret" {
  secret = "spaghet_datastream_user_secret"
}

locals {
  dataprodukt_arbeidsgiveropplysninger_db_credentials = jsondecode(
    data.google_secret_manager_secret_version.arbeidsgiveropplysninger_datastream_user_secret.secret_data
  )
}

locals {
  dataprodukt_forstegangsbehandling_db_credentials = jsondecode(
    data.google_secret_manager_secret_version.forstegangsbehandling_datastream_user_secret.secret_data
  )
}

locals {
  spaghet_db_credentials = jsondecode(
    data.google_secret_manager_secret_version.spaghet_datastream_user_secret.secret_data
  )
}
