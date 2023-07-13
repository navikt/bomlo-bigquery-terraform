resource "google_bigquery_dataset" "styringsinfo_dataset" {
  dataset_id    = "styringsinfo_dataset"
  location      = var.gcp_project["region"]
  friendly_name = "styringsinfo_dataset"
  labels        = {}
  description   = "Datagrunnlag tiltenkt brukt til styringsinformasjon. Basert på hendelser i ny sykepengeløsning (hentet fra tbd.rapid.v1). Merk at dette ikke er et totalbilde av sykepengesøknader. For rett tolkning se datafortellinger."

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
  timeouts {}
}

module "styringsinfo_sendt_soknad_view" {
  source              = "../modules/google-bigquery-view"
  deletion_protection = false
  dataset_id          = google_bigquery_dataset.styringsinfo_dataset.dataset_id
  view_id             = "styringsinfo_sendt_soknad_view"
  view_description    = "Basert på send_soknad_nav og send_soknad_arbeidsgiver-hendelser på tbd.rapid.v1."
  view_schema = jsonencode(
    [
      {
        name        = "syntetisk_id"
        type        = "STRING"
        description = "Syntetisk id tildelt ved lagring av hendelser i spre-styringsinfo."
      },
      {
        name        = "hendelse_id"
        type        = "STRING"
        description = "Intern id laget når hendelsen legges på tbd.rapid.v1"
      },
      {
        name        = "soknad_id"
        type        = "STRING"
        description = "Dokument-id (sykepengesøknad id fra Team Flex) til søknaden som hendelsen refererer til."
      },
      {
        name        = "korrigerer_soknad_id"
        type        = "STRING"
        description = "Dokument-id til tidligere innsendt søknad denne søknaden korrigerer."
      },
      {
        name        = "soknad_mottatt"
        type        = "TIMESTAMP"
        description = "Tidspunktet bruker sendte søknaden til arbeidsgiver eller NAV første gang."
      }
    ]
  )
  view_query = <<EOF
SELECT
    id AS syntetisk_id,
    hendelse_id,
    JSON_EXTRACT_SCALAR(melding, '$.id') AS soknad_id,
    korrigerer AS korrigerer_soknad_id,
    sendt AS soknad_mottatt
FROM `${var.gcp_project["project"]}.${google_bigquery_dataset.spre_styringsinfo_dataset.dataset_id}.public_sendt_soknad`
EOF
}

module "styringsinfo_vedtak_fattet_view" {
  source              = "../modules/google-bigquery-view"
  deletion_protection = false
  dataset_id          = google_bigquery_dataset.styringsinfo_dataset.dataset_id
  view_id             = "styringsinfo_vedtak_fattet_view"
  view_description    = "Basert på vedtak_fattet-hendelser på tbd.rapid.v1."
  view_schema = jsonencode(
    [
      {
        name        = "syntetisk_id"
        type        = "STRING"
        description = "Syntetisk id tildelt ved lagring av hendelser i spre-styringsinfo."
      },
      {
        name        = "hendelse_id"
        type        = "STRING"
        description = "Intern id laget når hendelsen legges på tbd.rapid.v1"
      },
      {
        name        = "vedtaksperiode_id"
        type        = "STRING"
        description = "Vedtaksperioden som hendelsen refererer til."
      },
      {
        name        = "utbetaling_id"
        type        = "STRING"
        description = "Eventuell utbetaling som vedtaket bidrar til."
      },
      {
        name        = "vedtak_fattet"
        type        = "TIMESTAMP"
        description = "Tidspunktet vedtaket ble fattet."
      }
    ]
  )
  view_query = <<EOF
SELECT
    id AS syntetisk_id,
    hendelse_id,
    JSON_EXTRACT_SCALAR(melding, '$.vedtaksperiodeId') AS vedtaksperiode_id,
    JSON_EXTRACT_SCALAR(melding, '$.utbetalingId') AS utbetaling_id,
    vedtak_fattet_tidspunkt AS vedtak_fattet
FROM `${var.gcp_project["project"]}.${google_bigquery_dataset.spre_styringsinfo_dataset.dataset_id}.public_vedtak_fattet`
EOF
}