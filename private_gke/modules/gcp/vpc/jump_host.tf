resource "google_compute_address" "jump_host_address" {
  name         = "jump-host-address"
  project      = var.project_id
  region       = var.region
  subnetwork   = google_compute_subnetwork.subnet.self_link
  address_type = "INTERNAL"
  address      = "10.128.0.10"
  description  = "Internal IP for Jump Host"
}

resource "google_compute_instance" "jump_host" {
  name         = "jump-host"
  project      = var.project_id
  zone         = "${var.region}-c"
  machine_type = "e2-medium"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link
    network_ip = google_compute_address.jump_host_address.address
  }
  tags = ["jump-host"]
}
