resource "aws_iam_role" "karpenter_role" {
  name = "KarpenterNodeRole-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  tags = merge(var.tags, {
    Name = "KarpenterNodeRole-${var.cluster_name}"
  })
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  role = aws_iam_role.karpenter_role.name
}

resource "aws_iam_role_policy" "karpenter_controller" {
  name = "karpenter-controller-policy"
  role = aws_iam_role.karpenter_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "ec2:TerminateInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts",
          "ssm:GetParameter"
        ]
        Resource = "*"
      }
    ]
  })
}
