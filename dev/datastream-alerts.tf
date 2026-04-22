# Referanse til notification channel for å sende alerts
data "google_monitoring_notification_channel" "slack-notification-channel" {
  display_name = "DEV Google Cloud Monitoring DEV"
  type         = "slack"
}

# Lag en liste over alle datastream stream_id som skal monitoreres
locals {
  datastreams = toset([
    google_datastream_stream.spre_styringsinfo_datastream.stream_id
  ])
}


# Lag en log-based metric som teller ERROR og CRITICAL logs fra datastream
# Dette fanger opp alle typer feil: autentisering, tilkobling, data-problemer, etc.
resource "google_logging_metric" "datastream_errors" {
  for_each = local.datastreams
  name     = replace("datastream-errors-${each.value}", "/[^a-zA-Z0-9_]/", "-")
  project  = var.gcp_project["project"]

  filter = <<-EOT
    resource.type="datastream.googleapis.com/Stream"
    resource.labels.stream_id="${each.value}"
    severity>=ERROR
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# Lag en monitorering policy for å sjekke om datastream har feilet
# Dette trigger på alle typer feil: credentials rotation, connection issues, unsupported data, etc.
resource "google_monitoring_alert_policy" "datastream_failure_alert_policy" {
  for_each     = local.datastreams
  display_name = "${each.value} failure alert policy"
  project      = var.gcp_project["project"]
  combiner     = "OR"
  severity     = "ERROR"

  # Slack notification channel for å sende alerts, #team-bømlo-data-alerts
  notification_channels = [
    data.google_monitoring_notification_channel.slack-notification-channel.name
  ]

  documentation {
    subject = "${each.value} har feilet i DEV!"
    content = "Datastream ${each.value} i DEV har logget ERROR eller CRITICAL meldinger. Dette kan skyldes credential rotation, tilkoblingsproblemer, data-format issues, eller andre feil. Sjekk logger i Google Cloud Console for detaljer."
  }

  # Lukk alerten automatisk etter 1 time uten nye error logs
  alert_strategy {
    auto_close = "3600s"
  }

  # Alert betingelser for når alerten skal trigges
  conditions {
    display_name = "${each.value} - Stream errors"

    condition_threshold {
      filter = "resource.type=\"datastream.googleapis.com/Stream\" AND resource.labels.stream_id=\"${each.value}\" AND metric.type=\"logging.googleapis.com/user/${google_logging_metric.datastream_errors[each.key].name}\""

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
      }

      # Hvor lenge thresholden skal overskrides før alerten trigges
      # Trigger umiddelbart når error logs oppdages
      duration = "60s"

      # Hvor mange timeseries som må over threshold for at alerten skal trigges
      # Vi har bare en timeserie
      trigger {
        count = 1
      }

      # Ingen data punkter er bra, skal tolkes som at det ikke er noen errors
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      # Threshold, trigger hvis det er noen error logs
      threshold_value = 0
      comparison      = "COMPARISON_GT"
    }
  }

  # Sørg for at log metric er opprettet før alert policy
  depends_on = [google_logging_metric.datastream_errors]
}
