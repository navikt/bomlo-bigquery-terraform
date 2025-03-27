
# Lag tre monitorering policies per datastream;
# - En for å sjekke antall unnsupported events
# - En for å sjekke data throughput i datastreamen

# Lag en liste over alle datastream stream_id som skal monitoreres
locals {
  datastreams = toset([
    google_datastream_stream.forstegangsbehandling_datastream.stream_id,
    google_datastream_stream.spaghet_datastream.stream_id,
    google_datastream_stream.spre_styringsinfo_datastream.stream_id,
    google_datastream_stream.annulleringer_datastream.stream_id
  ])
}

# Referanse til notification channel for å sende alerts
data "google_monitoring_notification_channel" "slack-notification-channel" {
  display_name = "Google Cloud Monitoring"
  type         = "slack"
}

# Lag en monitorering policy for å sjekke antall unnsupported events i alle datastreams
resource "google_monitoring_alert_policy" "datastream_unsupported_events_alert_policy" {
  for_each     = local.datastreams
  display_name = "${each.value} unsupported events alert policy"
  project      = var.gcp_project["project"]
  combiner     = "OR"
  severity     = "ERROR"

  # Slack notification channel for å sende alerts, #team-bømlo-data-alerts
  notification_channels = [
    data.google_monitoring_notification_channel.slack-notification-channel.name
  ]

  documentation {
    subject = "${each.value} har ustøttede events!"
    content = "Det er oppdaget ustøttede events i ${each.value}. Dette betyr at rader fra PostgreSQL ikke kan lastes inn i BigQuery på grunn av formatet på radene. Er det gjort endringrer på tabllene i PostgreSQL basen?"
  }

  # Lukk alerten automatisk etter 1 time uten data
  # Unsupported events telles bare når de finnes, og er absent når det ikke er noen
  alert_strategy {
    auto_close = "3600s"
  }

  # Alert betingelser for når alerten skal trigges
  conditions {
    display_name = "${each.value} - Stream unsupported event count"

    condition_threshold {
      filter = "resource.type = \"datastream.googleapis.com/Stream\" AND resource.labels.stream_id = \"${each.value}\" AND metric.type = \"datastream.googleapis.com/stream/unsupported_event_count\""

      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_NONE"
        per_series_aligner   = "ALIGN_MEAN"
      }

      # Hvor lenge thresholden skal overskrides før alerten trigges
      # Vår er satt til 1 minutt, og vi har et vindu på 5 minutter
      # Det vil si at vi får en alert et minutt etter det er unsupported events over threshold
      duration = "60s"

      # Hvor mange timeseries som må over threshold for at alerten skal trigges.
      # Vi har bare en timeserie
      trigger {
        count = 1
      }

      # Ingen data punkter er bra, skal tolkes som at det ikke er noen unsupported events
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      # Threshold, gjennomsnittlig mer enn 5 unsupported events de siste 5 minuttene
      threshold_value = 5
      comparison      = "COMPARISON_GT"
    }
  }
}

# Lag en monitorering policy for å throughput på events i alle datastreams
resource "google_monitoring_alert_policy" "datastream_throughput_events_alert_policy" {
  for_each     = local.datastreams
  display_name = "${each.value} throughput på events alert policy"
  project      = var.gcp_project["project"]
  combiner     = "OR"
  severity     = "ERROR"

  # Slack notification channel for å sende alerts, #team-bømlo-data-alerts
  notification_channels = [
    data.google_monitoring_notification_channel.slack-notification-channel.name
  ]

  documentation {
    subject = "${each.value} har veldig lav throughput av events!"
    content = "Det ser ut som ${each.value} har streamet ingen eller veldig få elementer til BigQuery de siste 5 timene. Dette kan bety veldig lav aktivitet i systemet, eller noe feil i appen som populerer PostgreSQL basen. Sjekk app loggene om det er noe feil."
  }

  # Alert betingelser for når alerten skal trigges
  conditions {
    display_name = "${each.value} - Stream event throughput"

    condition_threshold {
      filter = "resource.type = \"datastream.googleapis.com/Stream\" AND resource.labels.stream_id = \"${each.value}\" AND metric.type = \"datastream.googleapis.com/stream/event_count\" AND metric.labels.read_method = \"postgresql-cdc\""

      aggregations {
        alignment_period     = "3600s"
        cross_series_reducer = "REDUCE_NONE"
        per_series_aligner   = "ALIGN_MEAN"
      }

      # Hvor lenge thresholden skal overskrides før alerten trigges
      # Denne er satt til 6 timer, og vi har et vindu på 1 time
      # Det vil si at vi får en alert når throughput er under threshold i 6 timer sammenhengende
      # Annulleringer streamen har lavere volum i helgene, så vi har satt en høyere threshold på 24 timer
      duration = each.value == google_datastream_stream.annulleringer_datastream.stream_id ? "86400s" : "21600s"

      # Hvor mange timeseries som må over threshold for at alerten skal trigges.
      # Vi har bare en timeserie
      trigger {
        count = 1
      }

      # Ingen data punkter er bad, det skal trigge alert
      evaluation_missing_data = "EVALUATION_MISSING_DATA_ACTIVE"

      # Threshold, gjennomsnittlig mindre enn 1 event den siste timen
      threshold_value = 1
      comparison      = "COMPARISON_LT"
    }
  }
}