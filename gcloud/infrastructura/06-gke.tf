#https://github.com/hashicorp/learn-terraform-provision-gke-cluster/blob/main/gke.tf
#https://github.com/hashicorp/terraform-provider-google
#https://developer.hashicorp.com/terraform/tutorials/kubernetes/gke
#https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest
#https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/blob/master/modules/auth/outputs.tf


variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}

variable "gke_node_type" {
  default     = "e2-standard-4" #"e2-standard-2"
  description = "tipo de nodo"
}

variable "gke_name" {
  default     = "cluster-gke"
  description = "tipo de nodo"
}

module "gke_auth" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version = "24.1.0"
  #source = "./modules/auth"

  depends_on   = [google_container_cluster.primary]
  project_id   = var.project_id
  location     = google_container_cluster.primary.location
  cluster_name = google_container_cluster.primary.name
}

resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "kubeconfig-${var.env_name}"
}

# GKE cluster
data "google_container_engine_versions" "gke_version" {
  location       = var.region
  version_prefix = "1.27."
}

resource "google_container_cluster" "primary" {
  name     = var.gke_name
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = module.gcp-network.network_name
  subnetwork = module.gcp-network.subnets_names[0]
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name     = google_container_cluster.primary.name
  location = var.region
  cluster  = google_container_cluster.primary.name

  version    = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    preemptible  = true
    machine_type = var.gke_node_type
    tags         = ["gke-node", "${var.project_id}-gke"]
    disk_size_gb = 50
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

