data "google_secret_manager_secret_version" "forstegangsbehandling_datastream_user_secret" {
  secret = "forstegangsbehandling_datastream_user_secret"
}

data "google_secret_manager_secret_version" "spaghet_datastream_user_secret" {
  secret = "spaghet_datastream_user_secret"
}

data "google_secret_manager_secret_version" "spre_styringsinfo_datastream_user_secret" {
  secret = "spre_styringsinfo_datastream_user_secret"
}

data "google_secret_manager_secret_version" "spaghet_bigquery_connection_user_secret" {
  secret = "spaghet_bigquery_connection_user_secret"
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

data "google_secret_manager_secret_version" "spare_bigquery_connection_user_secret" {
  secret = "spare_bigquery_connection_user"
}

data "google_secret_manager_secret_version" "spedisjon_bigquery_connection_user_secret" {
  secret = "spedisjon_bigquery_connection_user"
}

# Locals for å decode secrets fra JSON format
locals {

  dataprodukt_forstegangsbehandling_db_credentials = jsondecode(
    data.google_secret_manager_secret_version.forstegangsbehandling_datastream_user_secret.secret_data
  )

  spaghet_db_credentials = jsondecode(
    data.google_secret_manager_secret_version.spaghet_datastream_user_secret.secret_data
  )

  spre_styringsinfo_db_credentials = jsondecode(
    data.google_secret_manager_secret_version.spre_styringsinfo_datastream_user_secret.secret_data
  )

  spaghet_bigquery_connection_user = jsondecode(
    data.google_secret_manager_secret_version.spaghet_bigquery_connection_user_secret.secret_data
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

  spare_bigquery_connection_user = jsondecode(
    data.google_secret_manager_secret_version.spare_bigquery_connection_user_secret.secret_data
  )

  spedisjon_bigquery_connection_user = jsondecode(
    data.google_secret_manager_secret_version.spedisjon_bigquery_connection_user_secret.secret_data
  )
}
