variable "project_name" {
  type    = string
  default = "multicloud-cicd"
}

variable "environment" {
  type = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  type    = string
  default = "asia-south1"
}

variable "subnet_cidr" {
  type    = string
  default = "10.10.0.0/20"
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}

variable "desired_node_count" {
  type    = number
  default = 2
}

variable "min_node_count" {
  type    = number
  default = 1
}

variable "max_node_count" {
  type    = number
  default = 4
}
