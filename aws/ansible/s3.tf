## S3 Bucket config#
#resource "aws_iam_role" "allow_s3_role" {
#  name = "allow_s3_role"
#
#  assume_role_policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Action": "sts:AssumeRole",
#      "Principal": {
#        "Service": "ec2.amazonaws.com"
#      },
#      "Effect": "Allow",
#      "Sid": ""
#    }
#  ]
#}
#EOF
#}
#
#resource "aws_iam_instance_profile" "allow_s3_profile" {
#  name = "allow_s3_profile"
#  role = aws_iam_role.allow_s3_role.name
#}
#
#resource "aws_iam_role_policy" "allow_s3_all_policy" {
#  name = "allow_s3_all_policy"
#  role = aws_iam_role.allow_s3_role.name
#
#  policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Action": [
#        "s3:*"
#      ],
#      "Effect": "Allow",
#      "Resource": [
#                "arn:aws:s3:::${local.s3_bucket_name}",
#                "arn:aws:s3:::${local.s3_bucket_name}/*"
#            ]
#    }
#  ]
#}
#EOF
#  }
#
#  resource "aws_s3_bucket" "key_bucket" {
#    bucket        = local.s3_bucket_name
#    acl           = "private"
#    force_destroy = true
#
#    tags = merge(local.common_tags, { Name = "${var.environment_tag}-bucket" })
#  }
#
#  resource "aws_s3_bucket_object" "pem" {
#    bucket = aws_s3_bucket.key_bucket.bucket
#    key = "${var.instance_key}.pem"
#    source = var.private_key_path
#  }
#