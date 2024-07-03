resource "google_bigquery_data_transfer_config" "query_config" {

  display_name           = "vedtaksperiode_venter_fra_spaghet"
  location               = "europe-north1"
  data_source_id         = "scheduled_query"
  schedule               = "every day 01:00"
  destination_dataset_id = google_bigquery_dataset.spaghet_dataset.dataset_id
  params = {
    destination_table_name_template = "public_vedtaksperiode_venter"
    write_disposition               = "WRITE_APPEND"
    query                           = "SELECT * FROM EXTERNAL_QUERY(\"tbd-prod-eacd.europe-north1.spaghet\", \"\"\"${file("./sql/vedtaksperiode_venter.sql")}\"\"\")"
  }
}
