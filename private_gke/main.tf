locals {
  network_name    = "prod-vpc"
  subnet_name     = "prod-isolated-subnet"
  pods_range_name = "subnet-pods"
  svc_range_name  = "subnet-services"
}

provider "google" {
  credentials = file(var.credentials_file_path)
  project     = var.project_id
  region      = var.region
}

module "gcp-vpc" {
  source          = "./modules/gcp/vpc"
  project_id      = var.project_id
  region          = var.region
  source_ranges   = var.source_ranges
  network_name    = local.network_name
  subnet_name     = local.subnet_name
  service_account = var.servie_account
  pods_range_name = local.pods_range_name
  svc_range_name  = local.svc_range_name
}

module "gcp-gke" {
  source                 = "./modules/gcp/gke"
  project_id             = var.project_id
  region                 = var.region
  service_account        = var.servie_account
  vpc_name               = local.network_name
  subnet_name            = local.subnet_name
  pods_range_name        = local.pods_range_name
  svc_range_name         = local.svc_range_name
  master_ipv4_cidr_block = "10.128.32.0/28"
}
