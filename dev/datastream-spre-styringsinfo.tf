resource "google_bigquery_dataset" "spre_styringsinfo_dataset" {
  dataset_id = "spre_styringsinfo_dataset"
  location   = var.gcp_project["region"]
  project    = var.gcp_project["project"]
  labels     = {}

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
  access {
    view {
      dataset_id = "styringsinfo_dataset"
      project_id = var.gcp_project["project"]
      table_id   = "styringsinfo_sendt_soknad_view"
    }
  }
  timeouts {}
}

resource "google_datastream_connection_profile" "spre_styringsinfo_postgresql_connection_profile" {
  location              = var.gcp_project["region"]
  display_name          = "spre-styringsinfo-postgresql-connection-profile"
  connection_profile_id = "spre-styringsinfo-postgresql-connection-profile"

  postgresql_profile {
    hostname = google_compute_instance.tbd_datastream_cloud_sql_proxy_vm.network_interface[0].network_ip
    port     = var.spre_styringsinfo_cloud_sql_port
    username = local.spre_styringsinfo_db_credentials["username"]
    password = local.spre_styringsinfo_db_credentials["password"]
    database = "spre-styringsinfo"
  }

  private_connectivity {
    private_connection = google_datastream_private_connection.tbd_datastream_private_connection.id
  }
}
