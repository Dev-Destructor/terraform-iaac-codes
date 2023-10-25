variable "region" {
  type        = string
  description = "Name of the region"
}

variable "profile" {
  type        = string
  description = "AWS profile of the user"
}

variable "vpc_cidr" {
  type        = string
  description = "cidr block for the VPC"
  default     = "192.168.0.0/16"
}

variable "public_subnet_01_cidr" {
  type        = string
  description = "value of the public subnet 01 cidr block"
  default     = "192.168.0.0/24"
}

variable "public_subnet_02_cidr" {
  type        = string
  description = "value of the public subnet 02 cidr block"
  default     = "192.168.64.0/24"
}

variable "private_subnet_01_cidr" {
  type        = string
  description = "value of the private subnet 01 cidr block"
  default     = "192.168.128.0/24"
}

variable "private_subnet_02_cidr" {
  type        = string
  description = "value of the private subnet 02 cidr block"
  default     = "192.168.192.0/24"
}
