provider "google" {
  # Configuración del proveedor de Google Cloud
}

resource "google_storage_bucket" "terraform_backend" {
  name     = "terraform-backend-cbc001"
  location = "europe-west1"
  versioning {
    enabled = true
  }
  # Otras configuraciones opcionales del bucket
}