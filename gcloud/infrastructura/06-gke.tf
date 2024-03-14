#https://github.com/hashicorp/learn-terraform-provision-gke-cluster/blob/main/gke.tf
#https://github.com/hashicorp/terraform-provider-google
#https://developer.hashicorp.com/terraform/tutorials/kubernetes/gke
#https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest
#https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/blob/master/modules/auth/outputs.tf


module "gke_auth" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version = "24.1.0"
  depends_on   = [module.gke]
  project_id   = var.project_id
  location     = module.gke.location
  cluster_name = module.gke.name
}

resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "kubeconfig-${var.env_name}"
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                 = var.project_id
  name                       = "${var.cluster_name}-${var.env_name}"
  region                     = var.region
  #zones                      = ["us-central1-a", "us-central1-b", "us-central1-f"]
  network                    = module.gcp-network.network_name
  subnetwork                 = module.gcp-network.subnets_names[0]
  ip_range_pods              = var.ip_range_pods_name
  ip_range_services          = var.ip_range_services_name
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  enable_private_endpoint    = true
  enable_private_nodes       = true
  #master_ipv4_cidr_block     = "10.0.0.0/28"

  node_pools = [
    {
      name                      = "default-node-pool"
      machine_type              = "e2-standard-2"#"e2-medium"
      node_locations            = "europe-west1-b,europe-west1-c,europe-west1-d"
      min_count                 = 1
      max_count                 = 2
      local_ssd_count           = 0
      spot                      = false
      disk_size_gb              = 30
      disk_type                 = "pd-standard"
      image_type                = "COS_CONTAINERD"
      enable_gcfs               = false
      enable_gvnic              = false
      logging_variant           = "DEFAULT"
      auto_repair               = true
      auto_upgrade              = true
      #service_account           = "project-service-account@<PROJECT ID>.iam.gserviceaccount.com"
      preemptible               = false
      initial_node_count        = 80
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  node_pools_labels = {
    all = {}
    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}
    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []
    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []
    default-node-pool = [
      "default-node-pool",
    ]
  }
}

#module "gke" {
#  source                 = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
#  version                = "24.1.0"
#  project_id             = var.project_id
#  name                   = "${var.cluster_name}-${var.env_name}"
#  regional               = true
#  region                 = var.region
#  network                = module.gcp-network.network_name
#  subnetwork             = module.gcp-network.subnets_names[0]
#  ip_range_pods          = var.ip_range_pods_name
#  ip_range_services      = var.ip_range_services_name
#  
#  node_pools = [
#    {
#      name                      = "node-pool"
#      machine_type              = "e2-standard-2"
#      node_locations            = "europe-west1-b,europe-west1-c,europe-west1-d"
#      min_count                 = 1
#      max_count                 = 2
#      disk_size_gb              = 30
#    },
#  ]
#}