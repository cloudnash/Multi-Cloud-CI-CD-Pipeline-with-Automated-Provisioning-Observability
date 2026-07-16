terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket = "REPLACE-WITH-YOUR-TF-STATE-BUCKET"
    key    = "staging/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "google" {
  project = var.gcp_project_id
  region  = "asia-south1"
}

variable "gcp_project_id" {
  description = "GCP project ID for staging"
  type        = string
}

variable "enable_aws" {
  description = "Whether to provision the AWS stack"
  type        = bool
  default     = true
}

variable "enable_gcp" {
  description = "Whether to provision the GCP stack"
  type        = bool
  default     = true
}

module "aws_stack" {
  source      = "../../modules/aws"
  count       = var.enable_aws ? 1 : 0
  environment = "staging"
}

module "gcp_stack" {
  source      = "../../modules/gcp"
  count       = var.enable_gcp ? 1 : 0
  environment = "staging"
  project_id  = var.gcp_project_id
}

output "aws_cluster_name" {
  value = var.enable_aws ? module.aws_stack[0].cluster_name : null
}

output "gcp_cluster_name" {
  value = var.enable_gcp ? module.gcp_stack[0].cluster_name : null
}
