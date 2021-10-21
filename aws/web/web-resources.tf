resource "aws_security_group" "sg" {
  name        = "allow_ssh_http"
  description = "Allow ssh http inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }
}


############################################################
######### Web Resources  ###################################
resource "aws_instance" "web" {
  count           = var.instance_count
#	ami             = data.aws_ami.aws-linux.id
  subnet_id       = aws_subnet.subnet[count.index % var.subnet_count].id

  ami             = "ami-05cd35b907b4ffe77" 
  instance_type   = var.instance_type
  key_name        = var.instance_key
  #subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.sg.id]

  connection {  
    type        = "ssh"
   	host        = self.public_ip
   	user        = "ec2-user"
   	private_key = file (var.private_key_path)
  }

#  user_data = <<-EOF
#  #!/bin/bash
#  sudo yum update -y
#  sudo amazon-linux-extras install docker
#  sudo service docker start
#  sudo docker run -d -p 80:80 -name nginx nginx
#  EOF

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install -y docker",
      "sudo service docker start",
      "sudo chkconfig docker on",
      "sudo docker info",
      "sudo docker run -d -p 80:80 --name nginx nginx",
      "sudo docker ps"
    ]
  }

  tags = {
    Name = "web_instance"
  }

  volume_tags = {
    Name = "web_instance"
  } 

}