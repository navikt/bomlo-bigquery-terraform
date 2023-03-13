resource "google_compute_network" "tbd_datastream_private_vpc" {
  name    = "tbd-datastream-vpc"
  project = var.gcp_project["project"]
}

// The IP-range in the VPC used for the Datastream VPC peering. If a Cloud SQL instance is assigned a private
// IP address, this is the range it will be assigned from.
resource "google_compute_global_address" "tbd_datastream_vpc_ip_range" {
  name          = "tbd-datastream-vpc-ip-range"
  project       = var.gcp_project["project"]
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  network       = google_compute_network.tbd_datastream_private_vpc.id
  prefix_length = 20
}

// Private connectivity lets you create a peered configuration between your VPC and Datastream’s private network.
// A single configuration can be used by all streams and connection profiles within a single region.
resource "google_datastream_private_connection" "tbd_datastream_private_connection" {
  location              = var.gcp_project["region"]
  display_name          = "tbd-datastream-private-connection"
  private_connection_id = "tbd-datastream-private-connection"

  vpc_peering_config {
    vpc    = google_compute_network.tbd_datastream_private_vpc.id
    subnet = "10.166.0.0/29"
  }
}