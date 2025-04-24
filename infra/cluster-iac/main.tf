terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  # You'll want to change this to your preferred backend
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.region
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Cluster endpoint configuration
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]  # Consider restricting this in production

  # Enable EKS Managed Node Groups
  eks_managed_node_groups = merge(
    {
      general = {
        desired_size = 2
        min_size     = 1
        max_size     = 3

        instance_types = ["t3.large"]
        capacity_type  = "ON_DEMAND"
      }
    },
    var.enable_gpu_nodes ? {
      gpu = {
        desired_size = 1
        min_size     = 0
        max_size     = 2

        instance_types = ["g4dn.xlarge"] # GPU instance type
        capacity_type  = "ON_DEMAND"

        labels = {
          "nvidia.com/gpu" = "true"
        }

        taints = [{
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NO_SCHEDULE"
        }]
      }
    } : {}
  )

  tags = var.tags
}
