terraform {
  backend "gcs" {
    bucket  = "terraform-backend-cbc001"
    prefix  = "terraform/state"
  }
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.47.0"
    }
  }
}