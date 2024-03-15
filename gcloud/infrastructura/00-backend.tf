terraform {
  backend "gcs" {
    bucket = "terraform-backend-cbc001"
    prefix = "terraform/state"
  }
}

#provider "google" {
#  # Configuración de autenticación y otras opciones
#}