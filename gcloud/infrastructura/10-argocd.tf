variable "namespace_argocd" {
  type    = string
  default = "argocd"
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace_argocd
  }
}

resource "helm_release" "argocd-staging" {
  name       = "argocd-staging"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "5.27.3"
  namespace  = var.namespace_argocd
  timeout    = "1200"
  values     = [templatefile("./argocd/install.yaml", {})]
}

resource "null_resource" "password" {
  provisioner "local-exec" {
    working_dir = "./argocd"
    command     = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath={.data.password} | base64 -d > argocd-login.txt"
  }
}

#resource "null_resource" "del-argo-pass" {
#  depends_on = [null_resource.password]
#  provisioner "local-exec" {
#    command = "kubectl -n argocd delete secret argocd-initial-admin-secret"
#  }
#}

