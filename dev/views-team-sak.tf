resource "google_bigquery_dataset" "saksbehandlingsstatistikk_til_team_sak_dataset" {
  dataset_id    = "saksbehandlingsstatistikk_til_team_sak_dataset"
  location      = var.gcp_project["region"]
  friendly_name = "saksbehandlingsstatistikk_til_team_sak_dataset"
  labels        = {}
  description   = "Datagrunnlag tiltenkt delt med Team Sak for saksbehandlingsstatistikk. Basert på hendelser i ny sykepengeløsning (hentet fra tbd.rapid.v1)"

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


module "saksbehandlingsstatistikk_til_team_sak_view" {
  source              = "../modules/google-bigquery-view"
  deletion_protection = false
  dataset_id          = google_bigquery_dataset.saksbehandlingsstatistikk_til_team_sak_dataset.dataset_id
  view_id             = "behandlingshendelse_view"
  view_description    = "Basert på en rekke hendelser på tbd.rapid.v1 som påvirker saksbehandling på sykepenger"
  view_schema = jsonencode(
    [
      {
        name        = "sekvensnummer"
        type        = "INT64"
        description = "Løpenummer tildelt ved lagring av rad i spre-styringsinfo. Brukt som identifikator for raden."
        mode        = "NULLABLE"
      },
      {
        name        = "sakYtelse"
        type        = "STRING"
        description = "Settes alltid til SYKEPENGER"
        mode        = "NULLABLE"
      },
      {
        name        = "sakUtland"
        type        = "STRING"
        description = "Settes alltid til NASJONAL"
        mode        = "NULLABLE"
      },
      {
        name        = "avsender"
        type        = "STRING"
        description = "Settes alltid til Speil (ny vedtaksløsning for sykepenger)"
        mode        = "NULLABLE"
      },
      {
        name        = "sakUuid"
        type        = "STRING"
        description = "UUID som identifiserer saken (vedtaksperioden)"
        mode        = "NULLABLE"
      },
      {
        name        = "behandlingUuid"
        type        = "STRING"
        description = "UUID som identifiserer behandlingen (generasjonen)"
        mode        = "NULLABLE"
      },
      {
        name        = "funksjonelltid"
        type        = "TIMESTAMP"
        description = "Funksjonell tid. @opprettet på hendelsen som har generert raden"
        mode        = "NULLABLE"
      },
      {
        name        = "teknisktid"
        type        = "TIMESTAMP"
        description = "Teknisk tid. Når hendelsen (raden) legges inn i databasen."
        mode        = "NULLABLE"
      },
      {
        name        = "relatertBehandlingUuid"
        type        = "STRING"
        description = "peker på relatert behandlingUuid hvis behandlingen gjelder samme sak"
        mode        = "NULLABLE"
      },
      {
        name        = "mottattTid"
        type        = "TIMESTAMP"
        description = "Tidspunktet da behandlingen oppstår"
        mode        = "NULLABLE"
      },
      {
        name        = "registrertTid"
        type        = "TIMESTAMP"
        description = "Tidspunkt da behandlingen første gang ble registrert i fagsystemet"
        mode        = "NULLABLE"
      },
      {
        name        = "behandlingtype"
        type        = "STRING"
        description = "Hvorvidt behandlingen er en førstegangsbehandling, omgjøring, reuvrdering osv"
        mode        = "NULLABLE"
      },
      {
        name        = "behandlingstatus"
        type        = "STRING"
        description = "Status for behandlingen. Endrer seg i løpet av livsløpet til en behandling"
        mode        = "NULLABLE"
      },
      {
        name        = "behandlingskilde"
        type        = "STRING"
        description = "Hva/hvem som er kilden til at behandlingen har oppstått i utgangspunktet"
        mode        = "NULLABLE"
      },
      {
        name        = "behandlingsresultat"
        type        = "STRING"
        description = "Resultatet av behandlingen"
        mode        = "NULLABLE"
      },
      {
        name        = "aktorId"
        type        = "STRING"
        description = "Identifiserer hvem behandlingen gjelder for"
        mode        = "NULLABLE"
      },
      {
        name        = "versjon"
        type        = "STRING"
        description = "Skjemaversjon. Ved endringer og utvidelser i felter øker vi versjon"
        mode        = "NULLABLE"
      }
    ]
  )
  view_query = <<EOF
WITH
  json_tidsstempler AS (
  SELECT
    sekvensnummer,
    LEFT(JSON_VALUE(DATA, "$.mottattTid"), 26) AS mottattTid_string,
    LEFT(JSON_VALUE(DATA, "$.registrertTid"), 26) AS registrertTid_string,
  FROM
   `${var.gcp_project["project"]}.${google_bigquery_dataset.spre_styringsinfo_dataset.dataset_id}.public_behandlingshendelse` )
SELECT
  b.sekvensnummer,
  "SYKEPENGER" AS sakYtelse,
  "NASJONAL" AS sakUtland,
  "Speil" AS avsender,
  sakid AS sakUuid,
  behandlingid AS behandlingUuid,
  funksjonelltid,
  teknisktid,
  JSON_VALUE(DATA, "$.relatertBehandlingId") AS relatertBehandlingUuid,
  CASE
    WHEN LENGTH(mottattTid_string) = 16 THEN PARSE_TIMESTAMP("%FT%R", mottattTid_string)
  ELSE
  TIMESTAMP(mottattTid_string)
  END
  AS mottattTid,
  CASE
    WHEN LENGTH(registrertTid_string) = 16 THEN PARSE_TIMESTAMP("%FT%R", registrertTid_string)
  ELSE
  TIMESTAMP(registrertTid_string)
END
  AS registrertTid,
  JSON_VALUE(DATA, "$.behandlingtype") AS behandlingtype,
  JSON_VALUE(DATA, "$.behandlingstatus") AS behandlingstatus,
  JSON_VALUE(DATA, "$.behandlingskilde") AS behandlingskilde,
  JSON_VALUE(DATA, "$.behandlingsresultat") AS behandlingsresultat,
  JSON_VALUE(DATA, "$.aktørId") AS aktorId,
  versjon
FROM
  json_tidsstempler
INNER JOIN
  `${var.gcp_project["project"]}.${google_bigquery_dataset.spre_styringsinfo_dataset.dataset_id}.public_behandlingshendelse` b
ON
  b.sekvensnummer = json_tidsstempler.sekvensnummer
  order by sekvensnummer
EOF
}
