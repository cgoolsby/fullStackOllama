variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "ollama-cluster"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "fullstack-ollama"
    Terraform   = "true"
  }
}
