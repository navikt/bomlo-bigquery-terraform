resource "google_bigquery_dataset" "spaghet_dataset" {
  dataset_id = "spaghet_dataset"
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

resource "google_datastream_connection_profile" "spaghet_postgresql_connection_profile" {
  location              = var.gcp_project["region"]
  display_name          = "spaghet-postgresql-connection-profile"
  connection_profile_id = "spaghet-postgresql-connection-profile"

  postgresql_profile {
    hostname = google_compute_instance.tbd_datastream_cloud_sql_proxy_vm.network_interface[0].network_ip
    port     = var.spaghet_cloud_sql_port
    username = local.spaghet_db_credentials["username"]
    password = local.spaghet_db_credentials["password"]
    database = "spaghet"
  }

  private_connectivity {
    private_connection = google_datastream_private_connection.tbd_datastream_private_connection.id
  }
}

resource "google_datastream_stream" "spaghet_datastream" {
  stream_id     = "spaghet-datastream"
  display_name  = "spaghet-datastream"
  desired_state = "RUNNING"
  project       = var.gcp_project["project"]
  location      = var.gcp_project["region"]
  labels        = {}
  backfill_all {}
  timeouts {}

  source_config {
    source_connection_profile = google_datastream_connection_profile.spaghet_postgresql_connection_profile.id

    postgresql_source_config {
      max_concurrent_backfill_tasks = 0
      publication                   = "spaghet_publication"
      replication_slot              = "spaghet_replication"

      include_objects {
        postgresql_schemas {
          schema = "public"

          postgresql_tables {
            table = "soknad_haandtert"
          }

          postgresql_tables {
            table = "godkjenning"
          }

          postgresql_tables {
            table = "funksjonell_feil"
          }

          postgresql_tables {
            table = "regelverksvarsel"
          }

          postgresql_tables {
            table = "annullering"
          }

          postgresql_tables {
            table = "begrunnelse"
          }

          postgresql_tables {
            table = "vedtaksperiode_tilstandsendring"
          }

          postgresql_tables {
            table = "varsel"
          }

          postgresql_tables {
            table = "soknad"
          }

          postgresql_tables {
            table = "vedtaksperiode_data"
          }

          postgresql_tables {
            table = "annullering_arsak"
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
        dataset_id = "${var.gcp_project["project"]}:${google_bigquery_dataset.spaghet_dataset.dataset_id}"
      }
    }
  }
}

