#####################
# locals
#####################

locals {
  common_tags = {
    BillingCode = var.billing_code_tag
	Environment = var.environment_tag
  }
  
  s3_bucket_name = "${var.bucket_name_prefix}-${var.environment_tag}-${random_integer.rand.result}"
}