variable "spinnaker_namespace" {
  type    = string
  default = "spinnaker"
}

resource "kubernetes_namespace" "spinnaker" {
  metadata {
    name = var.spinnaker_namespace
  }
}

resource "helm_release" "spinnaker" {
  chart      = "spinnaker"
  name       = "spinnaker"
  namespace  = var.spinnaker_namespace
  repository = "https://kubernetes-charts.storage.googleapis.com"

  values = [ 
        "spinnaker/values.yaml"
  ]
}
