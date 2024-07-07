variable "project_id" {
  description = "The ID of the terraform scripts will run."
  type        = string
}

variable "region" {
  description = "The region where the resources will be deployed."
  type        = string
}

variable "service_account" {
  description = "Terraform Service Account Name."
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
}

variable "pods_range_name" {
  description = "The name of the pods range"
  type        = string
}

variable "svc_range_name" {
  description = "The name of the services range"
  type        = string
}

variable "network_project_gcp_services" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com"
  ]
}

variable "source_ranges" {
  description = "The source ranges for the firewall rule"
  type        = list(string)
}
