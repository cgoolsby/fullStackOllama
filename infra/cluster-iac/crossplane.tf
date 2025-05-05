# Define a custom policy separately
resource "aws_iam_policy" "crossplane_s3_policy" {
  name        = "crossplane-s3-policy"
  description = "Custom policy for Crossplane S3 management"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutBucketTagging",
          "s3:GetBucketTagging",
          "s3:PutBucketVersioning",
          "s3:GetBucketVersioning",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketPublicAccessBlock"
        ],
        Resource = "*"
      }
    ]
  })
}

module "crossplane_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name = "crossplane-controller"

  # Attach both managed and custom policy
  role_policy_arns = {
    s3_managed = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    s3_custom  = aws_iam_policy.crossplane_s3_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn              = module.eks.oidc_provider_arn
      namespace_service_accounts = ["crossplane-system:crossplane"]
    }
  }

  tags = {
    Environment = "production"
  }
}
