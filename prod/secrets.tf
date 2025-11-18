data "google_secret_manager_secret_version" "arbeidsgiveropplysninger_datastream_user_secret" {
  secret = "arbeidsgiveropplysninger_datastream_user_secret"
}

data "google_secret_manager_secret_version" "forstegangsbehandling_datastream_user_secret" {
  secret = "forstegangsbehandling_datastream_user_secret"
}

data "google_secret_manager_secret_version" "spaghet_datastream_user_secret" {
  secret = "spaghet_datastream_user_secret"
}

data "google_secret_manager_secret_version" "spre_styringsinfo_datastream_user_secret" {
  secret = "spre_styringsinfo_datastream_user_secret"
}

data "google_secret_manager_secret_version" "annulleringer_datastream_user_secret" {
  secret = "annulleringer_datastream_user_secret"
}

data "google_secret_manager_secret_version" "spaghet_bigquery_connection_user_secret" {
  secret = "spaghet_bigquery_connection_user_secret"
}

data "google_secret_manager_secret_version" "annulleringer_bigquery_connection_user_secret" {
  secret = "annulleringer_bigquery_connection_user_secret"
}

data "google_secret_manager_secret_version" "forstegangsbehandlinger_bigquery_connection_user_secret" {
  secret = "forstegangsbehandlinger_bigquery_connection_user_secret"
}

data "google_secret_manager_secret_version" "spesialist_bigquery_connection_user_secret" {
  secret = "spesialist_bigquery_connection_user_secret"
}

data "google_secret_manager_secret_version" "spre_styringsinfo_bigquery_connection_user_secret" {
  secret = "spre_styringsinfo_bigquery_connection_user_secret"
}



# Locals for å decode secrets fra JSON format
locals {
  dataprodukt_arbeidsgiveropplysninger_db_credentials = jsondecode(
    data.google_secret_manager_secret_version.arbeidsgiveropplysninger_datastream_user_secret.secret_data
  )

  dataprodukt_forstegangsbehandling_db_credentials = jsondecode(
    data.google_secret_manager_secret_version.forstegangsbehandling_datastream_user_secret.secret_data
  )

  spaghet_db_credentials = jsondecode(
    data.google_secret_manager_secret_version.spaghet_datastream_user_secret.secret_data
  )

  spre_styringsinfo_db_credentials = jsondecode(
    data.google_secret_manager_secret_version.spre_styringsinfo_datastream_user_secret.secret_data
  )

  dataprodukt_annulleringer_db_credentials = jsondecode(
    data.google_secret_manager_secret_version.annulleringer_datastream_user_secret.secret_data
  )

  spaghet_bigquery_connection_user = jsondecode(
    data.google_secret_manager_secret_version.spaghet_bigquery_connection_user_secret.secret_data
  )

  annulleringer_bigquery_connection_user = jsondecode(
    data.google_secret_manager_secret_version.annulleringer_bigquery_connection_user_secret.secret_data
  )

  forstegangsbehandlinger_bigquery_connection_user = jsondecode(
    data.google_secret_manager_secret_version.forstegangsbehandlinger_bigquery_connection_user_secret.secret_data
  )

  spesialist_bigquery_connection_user = jsondecode(
    data.google_secret_manager_secret_version.spesialist_bigquery_connection_user_secret.secret_data
  )

  spre_styringsinfo_bigquery_connection_user = jsondecode(
    data.google_secret_manager_secret_version.spre_styringsinfo_bigquery_connection_user_secret.secret_data
  )

}
