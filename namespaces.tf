# Create namespaces for apps.  Prod should be on different cluster though!
resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
  }
}

resource "kubernetes_namespace" "stage" {
  metadata {
    name = "stage"
  }
}

resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
  }
}