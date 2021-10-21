# load balancer security group
resource "aws_security_group" "elb-sg" {
  name   = "web_elb_sg"
  vpc_id = aws_vpc.app_vpc.id
  
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
  
}

# load balancer
resource "aws_elb" "web-load-balancer" {
  name            ="web-elb"
  subnets         = aws_subnet.subnet[*].id
  security_groups = [aws_security_group.elb-sg.id]
  instances       = aws_instance.web[*].id

  
  listener {
    instance_port     = 80
	instance_protocol = "http"
	lb_port           = 80
	lb_protocol       = "http"
  }
  
}

output "aws_elb_public_dns" {
  value = aws_elb.web-load-balancer.dns_name
}

#add rules for waf