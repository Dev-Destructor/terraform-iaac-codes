variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "credentials_file_path" {
  description = "The path to the GCP credentials file"
  type        = string
}

variable "servie_account" {
  description = "The service account to use"
  type        = string
}

variable "source_ranges" {
  description = "The source ranges for the firewall rule"
  type        = list(string)
}
