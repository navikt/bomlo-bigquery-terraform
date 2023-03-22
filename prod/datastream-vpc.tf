resource "google_compute_network" "tbd_datastream_private_vpc" {
  name    = "tbd-datastream-vpc"
  project = var.gcp_project["project"]
}
