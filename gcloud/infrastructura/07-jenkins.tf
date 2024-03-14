resource "helm_release" "jenkins" {
  chart      = "jenkins"
  name       = "jenkins"
  namespace  = "default"
  repository = "https://charts.jenkins.io"

  values = [ 
        "jenkins/values.yaml"
  ]
}
