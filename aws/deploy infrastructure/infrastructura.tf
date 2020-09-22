#################
# variables
#################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {}
variable "region" {
  default ="eu-west-1"
}
variable "network_address_space" {
  default = "10.1.0.0/16"
}
variable "subnet1_address_space" {
  default = "10.1.0.0/24"
}
variable "subnet2_address_space" {
  default = "10.1.1.0/24"
}
variable "bucket_name_prefix" {}
variable "billing_code_tag" {}
variable "environment_tag" {}	

variable "instance_count" {
  default = 2
}

variable "subnet_count" {
  default = 2
}  

###################
# providers
###################

provider "aws" {
  region     = var.region
}

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

###################
# data
###################

data "aws_availability_zones" "available" {}

data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
	values = ["amzn-ami-hvm*"]
  }
  
  filter {
    name   = "root-device-type"
	values = ["ebs"]
  }
  
  filter {
    name   = "virtualization-type"
	values = ["hvm"]
  }

}

############################
# resources
############################

# random id
resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

# networking #
resource "aws_vpc" "vpc" {
  cidr_block           = var.network_address_space
#  enable_dns_hostnames = "true"

  tags = merge (local.common_tags, {Name = "${var.environment_tag}-vpc"})
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge (local.common_tags, {Name = "${var.environment_tag}-igw"})
}

resource "aws_subnet" "subnet" {
  count                   = var.subnet_count

  cidr_block              = cidrsubnet(var.network_address_space, 8, count.index)
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  
  tags = merge (local.common_tags, {Name = "${var.environment_tag}-subnet${count.index + 1}"})
}


# resource "aws_subnet" "subnet1" {
#   cidr_block              = var.subnet1_address_space
#   vpc_id                  = aws_vpc.vpc.id
#   map_public_ip_on_launch = "true"
#   availability_zone       = data.aws_availability_zones.available.names[0]
#   
#   tags = merge (local.common_tags, {Name = "${var.environment_tag}-subnet1"})
# }
# 
# resource "aws_subnet" "subnet2" {
#   cidr_block              = var.subnet2_address_space
#   vpc_id                  = aws_vpc.vpc.id
#   map_public_ip_on_launch = "true"
#   availability_zone       = data.aws_availability_zones.available.names[1]
#   
#   tags = merge (local.common_tags, {Name = "${var.environment_tag}-subnet2"})
# }
  
# routing #
resource "aws_route_table" "rtb" {
  vpc_id =  aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
	gateway_id =   aws_internet_gateway.igw.id
  }
  tags = merge (local.common_tags, {Name = "${var.environment_tag}-rtb"})

}

resource "aws_route_table_association" "rta-subnet" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.rtb.id
  
}

# resource "aws_route_table_association" "rta-subnet1" {
#   subnet_id      = aws_subnet.subnet1.id
#   route_table_id = aws_route_table.rtb.id
#   
# }
# 
# resource "aws_route_table_association" "rta-subnet2" {
#   subnet_id      = aws_subnet.subnet2.id
#   route_table_id = aws_route_table.rtb.id
#    
# }

# security groups #
# load balancer security group
resource "aws_security_group" "elb-sg" {
  name   = "nginx_elb_sg"
  vpc_id = aws_vpc.vpc.id
  
  ingress {
    from_port   = 80
	to_port     = 80
	protocol    = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
	to_port     = 0
	protocol    = -1
	cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge (local.common_tags, {Name = "${var.environment_tag}-elb-sg"})
}

# nginx security group 

resource "aws_security_group" "nginx-sg"{
  name        = "nginx_demos"
  description = "allow port for nginx demo"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
	to_port     = 22
	protocol    = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
	to_port     = 80
	protocol    = "tcp"
	cidr_blocks = [var.network_address_space]
  }
  egress {
    from_port   = 0
	to_port     = 0
	protocol    = -1
	cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge (local.common_tags, {Name = "${var.environment_tag}-nginx-sg"})
}

# load balancer
resource "aws_elb" "web" {
  name            ="nginx-elb"
  subnets         = aws_subnet.subnet[*].id
  security_groups = [aws_security_group.elb-sg.id]
  instances       = aws_instance.nginx[*].id

  
  listener {
    instance_port     = 80
	instance_protocol = "http"
	lb_port           = 80
	lb_protocol       = "http"
  }
  
  tags = merge (local.common_tags, {Name = "${var.environment_tag}-elb-web"})
}
# resource "aws_elb" "web" {
#   name            ="nginx-elb"
#   subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
#   security_groups = [aws_security_group.elb-sg.id]
#   instances       = [aws_instance.nginx1.id, aws_instance.nginx2.id]
# #  instances       = [aws_instance.nginx2.id]
#   
#   listener {
#     instance_port     = 80
# 	instance_protocol = "http"
# 	lb_port           = 80
# 	lb_protocol       = "http"
#   }
#   
#   tags = merge (local.common_tags, {Name = "${var.environment_tag}-elb-web"})
# }

# instance
   resource "aws_instance" "nginx" {
     count                  = var.instance_count
	 ami                    = data.aws_ami.aws-linux.id
     instance_type          = "t2.micro"
     subnet_id              = aws_subnet.subnet[count.index % var.subnet_count].id
     key_name               = var.key_name
     vpc_security_group_ids = [aws_security_group.nginx-sg.id]
     iam_instance_profile   = aws_iam_instance_profile.nginx_profile.name
      
     connection {
       type        = "ssh"
   	host        = self.public_ip
   	user        = "ec2-user"
   	private_key = file (var.private_key_path)
     }
    
     provisioner "file" {
      content = <<EOF
  access_key =
  secret_key =
  security_token =
  use_https = True
  bucket_location = UE
  
  EOF
      destination = "/home/ec2-user/.s3cfg"
    }
    
    provisioner "file" {
      content = <<EOF
  /var/log/nginx/*log {
      daily
      rotate 10
      missingok
      compress
      sharedscripts
      postrotate
      endscript
      lastaction
          INSTANCE_ID=`curl --silent http://169.254.169.254/latest/meta-data/instance-id`
          sudo /usr/local/bin/s3cmd sync --config=/home/ec2-user/.s3cfg /var/log/nginx/ s3://${aws_s3_bucket.web_bucket.id}/nginx/$INSTANCE_ID/
      endscript
  }
  EOF
      destination = "/home/ec2-user/nginx"
    }
    
    provisioner "remote-exec" {
      inline = [
        "sudo yum install nginx -y",
        "sudo service nginx start",
        "sudo cp /home/ec2-user/.s3cfg /root/.s3cfg",
        "sudo cp /home/ec2-user/nginx /etc/logrotate.d/nginx",
  	  "sudo yum -y install dos2unix",
  	  "sudo dos2unix /etc/logrotate.d/nginx",
  	  "sudo pip install --upgrade pip",
        "sudo /usr/local/bin/pip install s3cmd",
        "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/index.html .",
        "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/Globo_logo_Vert.png .",
        "sudo cp /home/ec2-user/index.html /usr/share/nginx/html/index.html --remove-destination",
        "sudo cp /home/ec2-user/Globo_logo_Vert.png /usr/share/nginx/html/Globo_logo_Vert.png --remove-destination",
        "sudo logrotate -f /etc/logrotate.conf"  
      ]
    }
  
     tags = merge (local.common_tags, {Name = "${var.environment_tag}-nginx${count.index + 1}"})
   }


#   resource "aws_instance" "nginx1" {
#     ami                    = data.aws_ami.aws-linux.id
#     instance_type          = "t2.micro"
#     subnet_id              = aws_subnet.subnet1.id
#     key_name               = var.key_name
#     vpc_security_group_ids = [aws_security_group.nginx-sg.id]
#     iam_instance_profile   = aws_iam_instance_profile.nginx_profile.name
#      
#    
#     connection {
#       type        = "ssh"
#   	host        = self.public_ip
#   	user        = "ec2-user"
#   	private_key = file (var.private_key_path)
#     }
#    
#     provisioner "file" {
#      content = <<EOF
#  access_key =
#  secret_key =
#  security_token =
#  use_https = True
#  bucket_location = UE
#  
#  EOF
#      destination = "/home/ec2-user/.s3cfg"
#    }
#    
#    provisioner "file" {
#      content = <<EOF
#  /var/log/nginx/*log {
#      daily
#      rotate 10
#      missingok
#      compress
#      sharedscripts
#      postrotate
#      endscript
#      lastaction
#          INSTANCE_ID=`curl --silent http://169.254.169.254/latest/meta-data/instance-id`
#          sudo /usr/local/bin/s3cmd sync --config=/home/ec2-user/.s3cfg /var/log/nginx/ s3://${aws_s3_bucket.web_bucket.id}/nginx/$INSTANCE_ID/
#      endscript
#  }
#  EOF
#      destination = "/home/ec2-user/nginx"
#    }
#    
#    provisioner "remote-exec" {
#      inline = [
#        "sudo yum install nginx -y",
#        "sudo service nginx start",
#        "sudo cp /home/ec2-user/.s3cfg /root/.s3cfg",
#        "sudo cp /home/ec2-user/nginx /etc/logrotate.d/nginx",
#  	  "sudo yum -y install dos2unix",
#  	  "sudo dos2unix /etc/logrotate.d/nginx",
#  	  "sudo pip install --upgrade pip",
#        "sudo /usr/local/bin/pip install s3cmd",
#        "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/index.html .",
#        "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/Globo_logo_Vert.png .",
#        "sudo cp /home/ec2-user/index.html /usr/share/nginx/html/index.html --remove-destination",
#        "sudo cp /home/ec2-user/Globo_logo_Vert.png /usr/share/nginx/html/Globo_logo_Vert.png --remove-destination",
#        "sudo logrotate -f /etc/logrotate.conf"  
#      ]
#    }
#  
#     tags = merge (local.common_tags, {Name = "${var.environment_tag}-nginx1"})
#   }
# 
# resource "aws_instance" "nginx2" {
#   ami                    = data.aws_ami.aws-linux.id
#   instance_type          = "t2.micro"
#   subnet_id              = aws_subnet.subnet2.id
#   key_name               = var.key_name
#   vpc_security_group_ids = [aws_security_group.nginx-sg.id]
#   iam_instance_profile   = aws_iam_instance_profile.nginx_profile.name
#   
#   connection {
#     type        = "ssh"
# 	host        = self.public_ip
# 	user        = "ec2-user"
# 	private_key = file (var.private_key_path)
#   }
#   
#   provisioner "file" {
#     content = <<EOF
# access_key =
# secret_key =
# security_token =
# use_https = True
# bucket_location = UE
# 
# EOF
#     destination = "/home/ec2-user/.s3cfg"
#   }
#   
#   provisioner "file" {
#     content = <<EOF
# /var/log/nginx/*log {
#     daily
#     rotate 10
#     missingok
#     compress
#     sharedscripts
#     postrotate
#     endscript
#     lastaction
#         INSTANCE_ID=`curl --silent http://169.254.169.254/latest/meta-data/instance-id`
#         sudo /usr/local/bin/s3cmd sync --config=/home/ec2-user/.s3cfg /var/log/nginx/ s3://${aws_s3_bucket.web_bucket.id}/nginx/$INSTANCE_ID/
#     endscript
# }
# EOF
#     destination = "/home/ec2-user/nginx"
#   }
#   
#   provisioner "remote-exec" {
#     inline = [
#       "sudo yum install nginx -y",
#       "sudo service nginx start",
#       "sudo cp /home/ec2-user/.s3cfg /root/.s3cfg",
#       "sudo cp /home/ec2-user/nginx /etc/logrotate.d/nginx",
# 	  "sudo yum -y install dos2unix",
# 	  "sudo dos2unix /etc/logrotate.d/nginx",
# 	  "sudo pip install --upgrade pip",
#       "sudo /usr/local/bin/pip install s3cmd",
#       "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/index.html .",
#       "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/Globo_logo_Vert.png .",
#       "sudo cp /home/ec2-user/index.html /usr/share/nginx/html/index.html --remove-destination",
#       "sudo cp /home/ec2-user/Globo_logo_Vert.png /usr/share/nginx/html/Globo_logo_Vert.png --remove-destination",
#       "sudo logrotate -f /etc/logrotate.conf"  
#     ]
#   }
# 
# 
#   tags = merge (local.common_tags, {Name = "${var.environment_tag}-nginx2"})
# }

# S3 Bucket config#
resource "aws_iam_role" "allow_nginx_s3" {
  name = "allow_nginx_s3"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "nginx_profile" {
  name = "nginx_profile"
  role = aws_iam_role.allow_nginx_s3.name
}

resource "aws_iam_role_policy" "allow_s3_all" {
  name = "allow_s3_all"
  role = aws_iam_role.allow_nginx_s3.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
                "arn:aws:s3:::${local.s3_bucket_name}",
                "arn:aws:s3:::${local.s3_bucket_name}/*"
            ]
    }
  ]
}
EOF

  }

  resource "aws_s3_bucket" "web_bucket" {
    bucket        = local.s3_bucket_name
    acl           = "private"
    force_destroy = true

    tags = merge(local.common_tags, { Name = "${var.environment_tag}-web-bucket" })

  }

  resource "aws_s3_bucket_object" "website" {
    bucket = aws_s3_bucket.web_bucket.bucket
    key = "/website/index.html"
    source = "./index.html"

  }

  resource "aws_s3_bucket_object" "graphic" {
    bucket = aws_s3_bucket.web_bucket.bucket
    key = "/website/Globo_logo_Vert.png"
    source = "./Globo_logo_Vert.png"

  }

######################################
# output
######################################

output "aws_elb_public_dns" {
  value = aws_elb.web.dns_name
}