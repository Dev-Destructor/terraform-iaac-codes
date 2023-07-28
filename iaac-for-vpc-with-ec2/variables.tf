variable "profile" {
  description = "AWS profile"
  type        = string
  default     = "destructor"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "key-pair" {
  description = "AWS key pair"
  type        = string
  default     = "tf-key-pair"
}

variable "instance" {
  description = "AWS instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_map" {
  type = map(string)
  default = {
    "eu-north-1"     = "ami-0989fb15ce71ba39e"
    "eu-west-3"      = "ami-05b5a865c3579bbc4"
    "eu-west-2"      = "ami-0eb260c4d5475b901"
    "eu-west-1"      = "ami-01dd271720c1ba44f"
    "ap-south-1"     = "ami-0f5ee92e2d63afc18"
    "ap-northeast-3" = "ami-0da13880f921c96a5"
    "ap-northeast-2" = "ami-0c9c942bd7bf113a2"
    "ap-northeast-1" = "ami-0d52744d6551d851e"
    "ca-central-1"   = "ami-0ea18256de20ecdfc"
    "sa-east-1"      = "ami-0af6e9042ea5a4e3e"
    "ap-southeast-1" = "ami-0df7a207adb9748c7"
    "ap-southeast-2" = "ami-0310483fb2b488153"
    "eu-central-1"   = "ami-04e601abe3e1a910f"
    "us-east-1"      = "ami-053b0d53c279acc90"
    "us-east-2"      = "ami-024e6efaf93d85776"
    "us-west-1"      = "ami-0f8e81a3da6e2510a"
    "us-west-2"      = "ami-03f65b8614a860c29"
  }
}

variable "auto-scale-max-size" {
  description = "Auto scale max size"
  type        = number
  default     = 2
}

variable "auto-scale-min-size" {
  description = "Auto scale min size"
  type        = number
  default     = 1
}
