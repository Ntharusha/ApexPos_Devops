variable "aws_region" {
  type        = string
  description = "AWS region for resource deployment"
  default     = "ap-south-1"
}

variable "project_name" {
  type        = string
  description = "Name of the project used for tagging resources"
  default     = "apexpos"
}

variable "environment" {
  type        = string
  description = "Target deployment environment"
  default     = "production"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "instance_type" {
  type        = string
  description = "EC2 instance size for running Kubernetes (k3s)"
  default     = "t3.small" # Modified to t3.small as requested by the user
}

variable "key_name" {
  type        = string
  description = "Name of the AWS EC2 SSH key pair"
  default     = "apex-pos"
}
