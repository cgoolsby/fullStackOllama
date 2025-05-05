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

# Configure the Kubernetes provider
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Get AWS account ID
data "aws_caller_identity" "current" {}

# Create ConfigMap for Terraform outputs
resource "kubernetes_config_map" "terraform_outputs" {
  metadata {
    name      = "terraform-outputs"
    namespace = "flux-system"
  }

  data = {
    AWS_ACCOUNT_ID      = data.aws_caller_identity.current.account_id
    EBS_CSI_ROLE_ARN   = aws_iam_role.ebs_csi_role.arn
    CLUSTER_NAME        = var.cluster_name
    CLUSTER_ENDPOINT    = module.eks.cluster_endpoint
    KARPENTER_ROLE_ARN = module.karpenter_controller_irsa.iam_role_arn
    KARPENTER_INSTANCE_PROFILE = aws_iam_instance_profile.karpenter.name
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.flux_system
  ]
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Enable OIDC provider for IRSA
  enable_irsa = true

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

        ami_type = "AL2_x86_64_GPU" # Specify the GPU-enabled AMI

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

  # Tag cluster security group for Karpenter discovery
  cluster_security_group_tags = {
    "karpenter.sh/discovery" = true
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = true
  }

  tags = var.tags
}
