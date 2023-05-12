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

resource "google_datastream_stream" "forstegangsbehandling_datastream" {
  stream_id     = "forstegangsbehandling-datastream"
  display_name  = "forstegangsbehandling-datastream"
  desired_state = "RUNNING"
  project       = var.gcp_project["project"]
  location      = var.gcp_project["region"]
  labels        = {}
  backfill_all {}
  timeouts {}

  source_config {
    source_connection_profile = google_datastream_connection_profile.forstegangsbehandling_postgresql_connection_profile.id

    postgresql_source_config {
      max_concurrent_backfill_tasks = 0
      publication                   = "dataprodukter_forstegangsbehandling_publication"
      replication_slot              = "dataprodukter_forstegangsbehandling_replication"

      include_objects {
        postgresql_schemas {
          schema = "public"

          postgresql_tables {
            table = "soknad"
            postgresql_columns {
              column = "hendelse_id"
            }
            postgresql_columns {
              column = "soknad_id"
            }
            postgresql_columns {
              column = "sykmelding_id"
            }
            postgresql_columns {
              column = "opprettet"
            }
            postgresql_columns {
              column = "forstegangsbehandling"
            }
          }
        }
      }
    }
  }

  destination_config {
    destination_connection_profile = google_datastream_connection_profile.datastream_bigquery_connection_profile.id

    bigquery_destination_config {
      data_freshness = "900s"

      single_target_dataset {
        dataset_id = "${var.gcp_project["project"]}:${google_bigquery_dataset.forstegangsbehandling_dataset.dataset_id}"
      }
    }
  }
}
