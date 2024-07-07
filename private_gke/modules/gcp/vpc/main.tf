# Enable APIs
resource "google_project_service" "network" {
  for_each                   = toset(var.network_project_gcp_services)
  project                    = var.project_id
  service                    = each.key
  disable_dependent_services = true
  disable_on_destroy         = false
}

# Create VPC
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Create Subnet
resource "google_compute_subnetwork" "subnet" {
  name                     = var.subnet_name
  ip_cidr_range            = "10.128.0.0/20"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  project                  = var.project_id
  private_ip_google_access = "true"

  secondary_ip_range {
    range_name    = var.pods_range_name
    ip_cidr_range = "10.0.0.0/10"
  }
  secondary_ip_range {
    range_name    = var.svc_range_name
    ip_cidr_range = "10.64.0.0/16"
  }
}

resource "google_compute_firewall" "rules" {
  project = var.project_id
  name    = "allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = var.source_ranges
}

resource "google_compute_firewall" "allow-internal-traffic" {
  project = var.project_id
  name    = "allow-internal-traffic"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.128.0.0/20"]
}

resource "google_compute_router" "router" {
  project = var.project_id
  name    = "nat-router"
  network = google_compute_network.vpc.name
  region  = var.region
}

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "5.2.0"
  project_id = var.project_id
  region     = var.region
  router     = google_compute_router.router.name
  name       = "nat-config"
}
