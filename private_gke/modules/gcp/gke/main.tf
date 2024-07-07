locals {
  cluster_type = "gke-standard-private"
}

# Get the service account email from name
data "google_service_account" "default" {
  account_id = var.service_account
}

# Enable APIs for Cluster project (GCP Project acting as Shared VPC service)
# Declare APIs
variable "cluster_project_gcp_services" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default = [
    "container.googleapis.com",
  ]
}
# Enable APIs
resource "google_project_service" "cluster" {
  for_each                   = toset(var.cluster_project_gcp_services)
  project                    = var.project_id
  service                    = each.key
  disable_dependent_services = true
  disable_on_destroy         = false
}

# Create GKE cluster
resource "google_container_cluster" "primary" {
  project                  = var.project_id
  name                     = "gke-cluster"
  location                 = "${var.region}-a"
  network                  = var.vpc_name
  subnetwork               = var.subnet_name
  remove_default_node_pool = true
  initial_node_count       = 1
  enable_shielded_nodes    = true

  release_channel {
    channel = "REGULAR"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.svc_range_name
  }
  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.128.0.10/32"
      display_name = "Allow from Jump Host"
    }
  }

  addons_config {
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  depends_on = [
    google_project_service.cluster,
  ]
}

# Create Node Pool for Backend Nodes
resource "google_container_node_pool" "backend-pool" {
  project    = var.project_id
  name       = "custom-pool"
  location   = "${var.region}-c"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    machine_type    = "e2-medium"
    image_type      = "UBUNTU_CONTAINERD"
    disk_type       = "pd-ssd"
    disk_size_gb    = 100
    service_account = data.google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/servicecontrol",
    ]
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    taint {
      key    = "node.cilium.io/agent-not-ready"
      value  = "true"
      effect = "NO_EXECUTE"
    }
  }

  network_config {
    enable_private_nodes = true
  }

  autoscaling {
    total_min_node_count = 2
    total_max_node_count = 5
    location_policy      = "BALANCED"
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}
