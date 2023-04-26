resource "google_bigquery_dataset" "arbeidsgiveropplysninger_dataset" {
  dataset_id = "arbeidsgiveropplysninger_dataset"
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
  access {
    view {
      dataset_id = "arbeidsgiveropplysninger_metrics"
      project_id = "helsearbeidsgiver-prod-8a1c"
      table_id   = "varsler_og_feil"
    }
  }
  access {
    view {
      dataset_id = "arbeidsgiveropplysninger_metrics"
      project_id = "helsearbeidsgiver-prod-8a1c"
      table_id   = "inntektsmelding_korrigeringer"
    }
  }
}

resource "google_datastream_connection_profile" "arbeidsgiveropplysninger_postgresql_connection_profile" {
  location              = var.gcp_project["region"]
  display_name          = "arbeidsgiveropplysninger-postgresql-connection-profile"
  connection_profile_id = "arbeidsgiveropplysninger-postgresql-connection-profile"

  postgresql_profile {
    hostname = google_compute_instance.tbd_datastream_cloud_sql_proxy_vm.network_interface[0].network_ip
    port     = var.dataprodukt_arbeidsgiveropplysninger_cloud_sql_port
    username = local.dataprodukt_arbeidsgiveropplysninger_db_credentials["username"]
    password = local.dataprodukt_arbeidsgiveropplysninger_db_credentials["password"]
    database = "arbeidsgiveropplysninger"
  }

  private_connectivity {
    private_connection = google_datastream_private_connection.tbd_datastream_private_connection.id
  }
}

resource "google_datastream_stream" "arbeidsgiveropplysninger_datastream" {
  stream_id     = "arbeidsgiveropplysninger-datastream"
  display_name  = "arbeidsgiveropplysninger-datastream"
  desired_state = "RUNNING"
  project       = var.gcp_project["project"]
  location      = var.gcp_project["region"]
  labels        = {}
  backfill_all {}
  timeouts {}

  source_config {
    source_connection_profile = google_datastream_connection_profile.arbeidsgiveropplysninger_postgresql_connection_profile.id

    postgresql_source_config {
      max_concurrent_backfill_tasks = 0
      publication                   = "dataprodukter_arbeidsgiveropplysninger_publication"
      replication_slot              = "dataprodukter_arbeidsgiveropplysninger_replication"

      exclude_objects {
        postgresql_schemas {
          schema = "public"

          postgresql_tables {
            table = "flyway_schema_history"
          }
        }
      }

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
        dataset_id = "${var.gcp_project["project"]}:${google_bigquery_dataset.arbeidsgiveropplysninger_dataset.dataset_id}"
      }
    }
  }
}
