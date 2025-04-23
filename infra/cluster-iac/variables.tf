variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "ollama-cluster"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_gpu_nodes" {
  description = "Whether to enable the GPU node group"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "ollama"
    ManagedBy   = "terraform"
  }
}
