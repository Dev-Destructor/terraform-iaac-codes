variable "project_id" {
  description = "The ID of the terraform scripts will run."
  type        = string
}

variable "region" {
  description = "The region where the resources will be deployed."
  type        = string
}

variable "service_account" {
  description = "Terraform Service Account Name. This SA is created within Terraform project (Project where terraform scripts are running)"
}

variable "network_project_gcp_services" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com"
  ]
}

variable "vpc_name" {
  description = "value of the vpc name"
  type        = string
}

variable "subnet_name" {
  description = "value of the subnet name"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "value of the master ipv4 cidr block"
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
