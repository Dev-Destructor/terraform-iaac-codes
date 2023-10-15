variable "region" {
  default = "ap-south-1"
}

variable "profile" {
  default = "destructor"
}

variable "vpc_cidr" {
  default = "192.168.0.0/16"
}

variable "public_subnet_01_cidr" {
  default = "192.168.0.0/24"
}

variable "public_subnet_02_cidr" {
  default = "192.168.64.0/24"
}

variable "private_subnet_01_cidr" {
  default = "192.168.128.0/24"
}

variable "private_subnet_02_cidr" {
  default = "192.168.192.0/24"
}
