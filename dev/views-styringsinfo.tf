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
        mode        = "NULLABLE"
      },
      {
        name        = "hendelse_id"
        type        = "STRING"
        description = "Intern id laget når hendelsen legges på tbd.rapid.v1"
        mode        = "NULLABLE"
      },
      {
        name        = "soknad_id"
        type        = "STRING"
        description = "Dokument-id (sykepengesøknad id fra Team Flex) til søknaden som hendelsen refererer til."
        mode        = "NULLABLE"
      },
      {
        name        = "korrigerer_soknad_id"
        type        = "STRING"
        description = "Dokument-id til tidligere innsendt søknad denne søknaden korrigerer."
        mode        = "NULLABLE"
      },
      {
        name        = "korrigerende"
        type        = "BOOLEAN"
        description = "Korrigerer søknaden en tidligere søknad?"
        mode        = "NULLABLE"
      },
      {
        name        = "soknad_mottatt"
        type        = "TIMESTAMP"
        description = "Tidspunktet bruker sendte søknaden til arbeidsgiver eller NAV første gang."
        mode        = "NULLABLE"
      }
    ]
  )
  view_query = <<EOF
SELECT
    id AS syntetisk_id,
    hendelse_id,
    JSON_EXTRACT_SCALAR(melding, '$.id') AS soknad_id,
    korrigerer AS korrigerer_soknad_id,
    korrigerer IS NOT NULL AS korrigerende,
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
        mode        = "NULLABLE"
      },
      {
        name        = "hendelse_id"
        type        = "STRING"
        description = "Intern id laget når hendelsen legges på tbd.rapid.v1"
        mode        = "NULLABLE"
      },
      {
        name        = "vedtaksperiode_id"
        type        = "STRING"
        description = "Vedtaksperioden som hendelsen refererer til."
        mode        = "NULLABLE"
      },
      {
        name        = "utbetaling_id"
        type        = "STRING"
        description = "Eventuell utbetaling som vedtaket bidrar til."
        mode        = "NULLABLE"
      },
      {
        name        = "vedtak_fattet"
        type        = "TIMESTAMP"
        description = "Tidspunktet vedtaket ble fattet."
        mode        = "NULLABLE"
      },
      {
        name        = "har_utbetaling"
        type        = "BOOLEAN"
        description = "Om vedtaket har en utbetaling knyttet til seg"
        mode        = "NULLABLE"
      }
    ]
  )
  view_query = <<EOF
SELECT
    id AS syntetisk_id,
    hendelse_id,
    JSON_EXTRACT_SCALAR(melding, '$.vedtaksperiodeId') AS vedtaksperiode_id,
    JSON_EXTRACT_SCALAR(melding, '$.utbetalingId') AS utbetaling_id,
    JSON_EXTRACT_SCALAR(melding, '$.utbetalingId') is not null as har_utbetaling,
    vedtak_fattet_tidspunkt AS vedtak_fattet
FROM `${var.gcp_project["project"]}.${google_bigquery_dataset.spre_styringsinfo_dataset.dataset_id}.public_vedtak_fattet`
EOF
}

module "styringsinfo_vedtak_fattet_mangler_soknad_view" {
  source              = "../modules/google-bigquery-view"
  deletion_protection = false
  dataset_id          = google_bigquery_dataset.styringsinfo_dataset.dataset_id
  view_description    = "Basert på vedtak_fattet-hendelser på tbd.rapid.v1 der vi IKKE finner tilhørende søknad. Dette kan skyldes at vi begynte å lese sendte søknader og fattede vedtak samtidig fra rapid, men det kan gå en stund før det fattes vedtak på den søknaden"
  view_id             = "styringsinfo_vedtak_fattet_mangler_soknad_view"
  view_schema = jsonencode(
    [
      {
        name        = "vedtak_fattet_hendelse_id"
        type        = "STRING"
        description = "Intern id laget når hendelsen legges på tbd.rapid.v1"
        mode        = "NULLABLE"
      },
      {
        name        = "vedtak_fattet"
        type        = "TIMESTAMP"
        description = "Tidspunktet vedtaket ble fattet."
        mode        = "NULLABLE"
      }
    ]
  )
  view_query = <<EOF
with vedtak_fattet_med_sist_mottatte_soknad as (select vedtak_hendelse_id
  FROM (select vedtak_hendelse_id, ROW_NUMBER() OVER (PARTITION BY vdm.vedtak_hendelse_id ORDER BY sso.sendt DESC) as rangering
        from `${var.gcp_project["project"]}.${google_bigquery_dataset.spre_styringsinfo_dataset.dataset_id}.public_vedtak_dokument_mapping` vdm
                 inner join
             `${var.gcp_project["project"]}.${google_bigquery_dataset.spre_styringsinfo_dataset.dataset_id}.public_sendt_soknad` sso
             on vdm.dokument_hendelse_id = sso.hendelse_id)
  where rangering = 1)
select hendelse_id as vedtak_fattet_hendelse_id, vedtak_fattet_tidspunkt vedtak_fattet
from `${var.gcp_project["project"]}.${google_bigquery_dataset.spre_styringsinfo_dataset.dataset_id}.public_vedtak_fattet` vfa
where vfa.hendelse_id not in (select vedtak_hendelse_id from vedtak_fattet_med_sist_mottatte_soknad)
EOF
}

module "styringsinfo_vedtak_forkastet_view" {
  source              = "../modules/google-bigquery-view"
  deletion_protection = false
  dataset_id          = google_bigquery_dataset.styringsinfo_dataset.dataset_id
  view_id             = "styringsinfo_vedtak_forkastet_view"
  view_description    = "Basert på vedtak_forkastet-hendelser på tbd.rapid.v1."
  view_schema = jsonencode(
    [
      {
        name        = "syntetisk_id"
        type        = "STRING"
        description = "Syntetisk id tildelt ved lagring av hendelser i spre-styringsinfo."
        mode        = "NULLABLE"
      },
      {
        name        = "hendelse_id"
        type        = "STRING"
        description = "Intern id laget når hendelsen legges på tbd.rapid.v1"
        mode        = "NULLABLE"
      },
      {
        name        = "vedtaksperiode_id"
        type        = "STRING"
        description = "Vedtaksperioden som hendelsen refererer til."
        mode        = "NULLABLE"
      },
      {
        name        = "vedtak_forkastet"
        type        = "TIMESTAMP"
        description = "Tidspunktet vedtaket ble forkastet."
        mode        = "NULLABLE"
      }
    ]
  )
  view_query = <<EOF
SELECT
    id AS syntetisk_id,
    hendelse_id,
    JSON_EXTRACT_SCALAR(melding, '$.vedtaksperiodeId') AS vedtaksperiode_id,
    forkastet_tidspunkt AS vedtak_forkastet
FROM `${var.gcp_project["project"]}.${google_bigquery_dataset.spre_styringsinfo_dataset.dataset_id}.public_vedtak_forkastet`
EOF
}

module "styringsinfo_vedtak_tidsbruk" {
  source              = "../modules/google-bigquery-view"
  deletion_protection = false
  dataset_id          = google_bigquery_dataset.styringsinfo_dataset.dataset_id
  view_id             = "styringsinfo_vedtak_tidsbruk"
  view_description    = "Beregner tidsbruk fra søknad er mottatt til vedtak er fattet for den sist sendte søknaden som inngikk i vedtaket."
  view_schema = jsonencode(
    [
      {
        name        = "vedtak_fattet_dato"
        type        = "DATE"
        description = "Dato for når vedtaket ble fattet"
        mode        = "NULLABLE"
      },
      {
        name        = "har_utbetaling"
        type        = "BOOLEAN"
        description = "Om vedtaket har en utbetaling knyttet til seg"
        mode        = "NULLABLE"
      },
      {
        name        = "aar"
        type        = "INT64"
        description = "Antall år mellom søknad ble mottatt og vedtak ble fattet. Om denne blir større enn 0 er vi i trøbbel"
        mode        = "NULLABLE"
      },
      {
        name        = "maaneder"
        type        = "INT64"
        description = "Antall måneder mellom søknad ble mottatt og vedtak ble fattet. Mellom 0 og 12"
        mode        = "NULLABLE"
      },
      {
        name        = "dager"
        type        = "INT64"
        description = "Antall dager mellom søknad ble mottatt og vedtak ble fattet. Mellom 0 og 30"
        mode        = "NULLABLE"
      },
      {
        name        = "dager_brukt"
        type        = "INT64"
        description = "Absolutt antall dager forløpt fra søknad mottatt til vedtak fattet. Om dette er 0 ble vedtaket fattet innen 24 timer fra vi mottok søknaden."
        mode        = "NULLABLE"
      },
      {
        name        = "timer_brukt"
        type        = "INT64"
        description = "Absolutt antall timer forløpt fra søknad mottatt til vedtak fattet. Om dette er 0 ble vedtaket fattet innen 60 minutter fra vi mottok søknaden."
        mode        = "NULLABLE"
      }
    ]
  )
  view_query = <<EOF
with tidsbruk as (
select 
  sso.sendt as soknad_sendt,
  vfa.vedtak_fattet as vedtak_fattet,
  vfa.har_utbetaling,
  JUSTIFY_INTERVAL(vfa.vedtak_fattet - sso.sendt) as tid,
  date_diff(vfa.vedtak_fattet, sso.sendt, day) as dager_brukt,
  date_diff(vfa.vedtak_fattet, sso.sendt, hour) as timer_brukt,
  ROW_NUMBER() OVER (PARTITION BY vfa.hendelse_id ORDER BY sso.sendt DESC) as rangering --siste søknad har rangering 1
from
  `${var.gcp_project["project"]}.${google_bigquery_dataset.styringsinfo_dataset.dataset_id}.styringsinfo_vedtak_fattet_view` vfa,
  `${var.gcp_project["project"]}.${google_bigquery_dataset.spre_styringsinfo_dataset.dataset_id}.public_vedtak_dokument_mapping` vdm,
  `${var.gcp_project["project"]}.${google_bigquery_dataset.spre_styringsinfo_dataset.dataset_id}.public_sendt_soknad` sso
where vfa.hendelse_id=vdm.vedtak_hendelse_id and sso.hendelse_id=vdm.dokument_hendelse_id)
select
  date(tidsbruk.vedtak_fattet) as vedtak_fattet_dato,
  har_utbetaling,
  extract(YEAR from tid) AS aar,
  extract(MONTH from tid) AS maaneder,
  extract(DAY from tid) AS dager,
  dager_brukt,
  timer_brukt
from tidsbruk
where rangering=1
EOF
}
