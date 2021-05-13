provider "helm" {
  kubernetes {
    config_path = module.eks.kubeconfig_filename
  }
}

# Automatically create Route53 DNS records
resource "helm_release" "external-dns" {
  name             = "external-dns"
  namespace        = "infrastructure"
  chart            = "external-dns"
  repository       = "https://charts.bitnami.com/bitnami"
  create_namespace = true

  set {
    name  = "provider"
    value = "aws"
  }
  set {
    name  = "aws.preferCNAME"
    value = true
  }
  set {
    name  = "txtPrefix"
    value = "txt"
  }
  set {
    name  = "policy"
    value = "sync"
  }
}

# Create ALBs/NLBs/ELBs easily
resource "helm_release" "aws-load-balancer-controller" {
  name             = "aws-load-balancer-controller"
  namespace        = "infrastructure"
  chart            = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  create_namespace = true

  set {
    name  = "autoDiscoverAwsRegion"
    value = true
  }

  set {
    name  = "autoDiscoverAwsVpcID"
    value = true
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_id
  }
}

# # Monitoring Stack
# resource "helm_release" "kube-prometheus-stack" {
#   name             = "kube-prometheus-stack"
#   namespace        = "infrastructure"
#   chart            = "kube-prometheus-stack"
#   repository       = "https://prometheus-community.github.io/helm-charts"
#   create_namespace = true
#   values = [
#     file("${path.module}/values/kube-prometheus-stack-values.yaml"),
#   ]

# }
