variable "region" {
  default = "us-west-2"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "creds_path" {
  default = "~/.aws/"
}

variable "creds_file" {
  default = "credentials"
}

variable "instance_key" {
  default = "aws_ec2_pem_file_name2"
}

variable "vpc_cidr" {
  default = "178.0.0.0/16"
}

variable "private_key_path" {
}

variable "instance_count" {
  default = 2
}

variable "subnet_count" {
  default = 1
}  

variable "private_subnets" {
  type = list
}

variable "public_subnets" {
  type =list
}

variable "bucket_name_prefix" {default = "keys"}

variable "billing_code_tag" { default = "no aplica"}

variable "environment_tag" {default = "test"}
