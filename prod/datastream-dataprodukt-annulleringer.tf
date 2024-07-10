resource "google_bigquery_dataset" "annulleringer_dataset" {
  dataset_id = "annulleringer_dataset"
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

resource "google_datastream_connection_profile" "annulleringer_postgresql_connection_profile" {
  location              = var.gcp_project["region"]
  display_name          = "annulleringer-postgresql-connection-profile"
  connection_profile_id = "annulleringer-postgresql-connection-profile"

  postgresql_profile {
    hostname = google_compute_instance.tbd_datastream_cloud_sql_proxy_vm.network_interface[0].network_ip
    port     = var.dataprodukt_annulleringer_cloud_sql_port
    username = local.dataprodukt_annulleringer_db_credentials["username"]
    password = local.dataprodukt_annulleringer_db_credentials["password"]
    database = "annulleringer"
  }

  private_connectivity {
    private_connection = google_datastream_private_connection.tbd_datastream_private_connection.id
  }
}

resource "google_datastream_stream" "annulleringer_datastream" {
  stream_id     = "annulleringer-datastream"
  display_name  = "annulleringer-datastream"
  desired_state = "RUNNING"
  project       = var.gcp_project["project"]
  location      = var.gcp_project["region"]
  labels        = {}
  backfill_all {}
  timeouts {}

  source_config {
    source_connection_profile = google_datastream_connection_profile.annulleringer_postgresql_connection_profile.id

    postgresql_source_config {
      max_concurrent_backfill_tasks = 0
      publication                   = "dataprodukt_annulleringer_publication"
      replication_slot              = "dataprodukt_annulleringer_replication"

      # Exlude flyway schema history table
      exclude_objects {
        postgresql_schemas {
          schema = "public"

          postgresql_tables {
            table = "flyway_schema_history"
          }
        }
      }

      # Include all tables in the public schema, other than already excluded
      include_objects {
        postgresql_schemas {
          schema = "public"
        }
      }
    }
  }

  destination_config {
    destination_connection_profile = google_datastream_connection_profile.datastream_bigquery_connection_profile.id

    bigquery_destination_config {
      data_freshness = "900s"

      single_target_dataset {
        dataset_id = "${var.gcp_project["project"]}:${google_bigquery_dataset.annulleringer_dataset.dataset_id}"
      }
    }
  }
}
