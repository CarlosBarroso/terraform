output "cluster_name" {
  description = "Cluster name"
  value       = google_container_cluster.primary.name
}

output "coenxion" {
  description = "coenxión al cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region=${var.region} "
}