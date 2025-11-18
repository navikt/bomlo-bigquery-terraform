data "google_sql_database_instance" "spesialist-instance-db" {
  name = "spesialist"
}

resource "google_bigquery_connection" "spesialist-bigquery-connection" {
  connection_id = "spesialist"
  location      = "europe-north1"
  friendly_name = "spesialist"
  description   = "Kobling til spesialist postgres basen fra BigQuery"
  cloud_sql {
    instance_id = data.google_sql_database_instance.spesialist-instance-db.connection_name
    database    = "spesialist"
    type        = "POSTGRES"
    credential {
      username = local.spesialist_bigquery_connection_user.username
      password = local.spesialist_bigquery_connection_user.password
    }
  }
}

resource "google_bigquery_connection" "spaghet-bigquery-connection" {
  connection_id = "spaghet"
  location      = "europe-north1"
  friendly_name = "spaghet"
  description   = "Kobling til spaghet postgres basen fra BigQuery"
  cloud_sql {
    instance_id = data.google_sql_database_instance.spaghet_db.connection_name
    database    = "spaghet"
    type        = "POSTGRES"
    credential {
      username = local.spaghet_bigquery_connection_user.username
      password = local.spaghet_bigquery_connection_user.password
    }
  }
}

resource "google_bigquery_connection" "annulleringer-bigquery-connection" {
  connection_id = "dataprodukt-annulleringer"
  location      = "europe-north1"
  friendly_name = "Dataprodukt annulleringer"
  description   = "Kobling til dataproduktet annulleringer sin postgres base fra BigQuery"
  cloud_sql {
    instance_id = data.google_sql_database_instance.annulleringer_db.connection_name
    database    = "annulleringer"
    type        = "POSTGRES"
    credential {
      username = local.annulleringer_bigquery_connection_user.username
      password = local.annulleringer_bigquery_connection_user.password
    }
  }
}

resource "google_bigquery_connection" "forstegangsbehandling-bigquery-connection" {
  connection_id = "dataprodukt-forstegangsbehandlinger"
  location      = "europe-north1"
  friendly_name = "Dataprodukt forstegangsbehandling"
  description   = "Kobling til dataproduktet førstegangsbehandling basen fra BigQuery"
  cloud_sql {
    instance_id = data.google_sql_database_instance.dataprodukt_forstegangsbehandling_db.connection_name
    database    = "forstegangsbehandling"
    type        = "POSTGRES"
    credential {
      username = local.forstegangsbehandlinger_bigquery_connection_user.username
      password = local.forstegangsbehandlinger_bigquery_connection_user.password
    }
  }
}

resource "google_bigquery_connection" "spre_styringsinfo-bigquery-connection" {
  connection_id = "spre_styringsinfo"
  location      = "europe-north1"
  friendly_name = "spre_styringsinfo"
  description   = "Kobling til spaghet postgres basen fra BigQuery"
  cloud_sql {
    instance_id = data.google_sql_database_instance.spre_styringsinfo_db.connection_name

    database = "spre-styringsinfo"
    type     = "POSTGRES"
    credential {
      username = local.spre_styringsinfo_bigquery_connection_user.username
      password = local.spre_styringsinfo_bigquery_connection_user.password
    }
  }
}