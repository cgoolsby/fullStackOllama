resource "null_resource" "create_flux_ns" {
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG="$(mktemp)"
      aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name} --kubeconfig "$KUBECONFIG"
      kubectl get ns flux-system || kubectl create ns flux-system
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  triggers = {
    cluster_endpoint = module.eks.cluster_endpoint
  }

  depends_on = [module.eks]
}