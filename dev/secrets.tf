data "google_secret_manager_secret_version" "spre_styringsinfo_datastream_user_secret" {
  secret = "spre_styringsinfo_datastream_user_secret"
}

locals {
  spre_styringsinfo_db_credentials = jsondecode(
    data.google_secret_manager_secret_version.spre_styringsinfo_datastream_user_secret.secret_data
  )
}
