# Create ConfigMap for Terraform outputs
resource "kubernetes_config_map" "terraform_outputs" {
  metadata {
    name      = "terraform-outputs"
    namespace = "flux-system"
  }

  data = {
    AWS_ACCOUNT_ID     = data.aws_caller_identity.current.account_id
    EBS_CSI_ROLE_ARN   = aws_iam_role.ebs_csi_role.arn
    CLUSTER_NAME       = var.cluster_name
    CLUSTER_ENDPOINT   = module.eks.cluster_endpoint
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.flux_system
  ]
}
