variable "gcp_project" {
  description = "GCP project and region defaults."
  type        = map(string)
  default = {
    region  = "europe-north1",
    zone    = "europe-north1-a",
    project = "tbd-prod-eacd"
  }
}


variable "dataprodukt_forstegangsbehandling_cloud_sql_port" {
  description = "The port exposed by the dataprodukt_forstegangsbehandling database Cloud SQL instance."
  type        = string
  default     = "5433"
}

variable "spaghet_cloud_sql_port" {
  description = "The port exposed by the spaghet database Cloud SQL instance."
  type        = string
  default     = "5434"
}

variable "spre_styringsinfo_cloud_sql_port" {
  description = "The port exposed by the spre-styringsinfo database Cloud SQL instance."
  type        = string
  default     = "5435"
}

variable "dataprodukt_annulleringer_cloud_sql_port" {
  description = "The port exposed by the spre-styringsinfo database Cloud SQL instance."
  type        = string
  default     = "5436"
}
