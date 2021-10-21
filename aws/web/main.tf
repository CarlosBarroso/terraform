# ../terraform init
# ../terraform plan -var-file=aws.tfvars
# ../terraform apply -var-file=aws.tfvars -auto-approve
# ../terraform destroy -auto-approve

terraform {
  required_providers {
    aws = {
      source  = "hasicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region                  = var.region
  shared_credentials_file = "var.creds_path.var.creds_file"
  profile                 = "default"
}

# random id
resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

#montar un balanceador y dos instancias cada una en una zona distinta.


#resource "time_sleep" "wait_30_seconds" {
#  depends_on = [aws_instance.web]
#
#  create_duration = "30s"
#}




