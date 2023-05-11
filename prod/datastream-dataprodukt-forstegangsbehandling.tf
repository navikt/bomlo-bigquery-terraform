resource "google_bigquery_dataset" "forstegangsbehandling_dataset" {
  dataset_id = "forstegangsbehandling_dataset"
  location   = var.gcp_project["region"]
  project    = var.gcp_project["project"]
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
}

resource "google_datastream_connection_profile" "forstegangsbehandling_postgresql_connection_profile" {
  location              = var.gcp_project["region"]
  display_name          = "forstegangsbehandling-postgresql-connection-profile"
  connection_profile_id = "forstegangsbehandling-postgresql-connection-profile"

  postgresql_profile {
    hostname = google_compute_instance.tbd_datastream_cloud_sql_proxy_vm.network_interface[0].network_ip
    port     = var.dataprodukt_forstegangsbehandling_cloud_sql_port
    username = local.dataprodukt_forstegangsbehandling_db_credentials["username"]
    password = local.dataprodukt_forstegangsbehandling_db_credentials["password"]
    database = "forstegangsbehandling"
  }

  private_connectivity {
    private_connection = google_datastream_private_connection.tbd_datastream_private_connection.id
  }
}