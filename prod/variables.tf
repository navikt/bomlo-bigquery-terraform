variable "gcp_project" {
  description = "GCP project and region defaults."
  type        = map(string)
  default = {
    region  = "europe-north1",
    zone    = "europe-north1-a",
    project = "tbd-prod-eacd"
  }
}

variable "dataprodukt_arbeidsgiveropplysninger_cloud_sql_port" {
  description = "The port exposed by the dataprodukt_arbeidsgiveropplysninger database Cloud SQL instance."
  type        = string
  default     = "5432"
}

variable "dataprodukt_forstegangsbehandling_cloud_sql_port" {
  description = "The port exposed by the dataprodukt_forstegangsbehandling database Cloud SQL instance."
  type        = string
  default     = "5433"
}
