resource "aws_security_group" "sg" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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
######### ansible Resources  ###############################
resource "aws_instance" "ansible" {
  
  subnet_id       = module.vpc.public_subnets[0]

  ami             = "ami-05cd35b907b4ffe77" 
  instance_type   = var.instance_type
  key_name        = var.instance_key
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

  provisioner "file" {
      content = <<EOF
  [user]
    name = Carlos Barroso
    email = cbc_sg@yahoo.es
  EOF
      destination = "/home/ec2-user/.gitconfig"
  }

  provisioner "file" {
      content = <<EOF
[defaults]
nocows = 1
hostfile = /home/ec2-user/inventory
private_key_file = /home/ec2-user/${var.instance_key}.pem
remote_user = ec2-user
interpreter_python= /usr/bin/python3
  EOF
      destination = "/home/ec2-user/.ansible.cfg"
  }

  provisioner "file" {
      content = <<EOF
---
all:
  hosts: 
    rabbitmq:
      ansible_host: ${aws_instance.RabbitMQ.private_ip} 
      ansible_private_key_file: /home/ec2-user/${var.instance_key}.pem
      ansible_ssh_user: ec2-user
  EOF
      destination = "/home/ec2-user/inventory"
  }

  provisioner "file" {
    source      = var.private_key_path
    destination = "/home/ec2-user/${var.instance_key}.pem"
  }

  provisioner "file" {
    content = <<EOF
---
- name: configure localhost
  hosts: localhost
  tasks:
  - name: Install git
    become: yes
    yum:
      pkg=git 
      state=installed

- name: configure RabbitMQ
  hosts: rabbitmq
  become: yes
  tasks:
  - name: configure / Update yum packages
    yum:
      name: '*'
      state: latest
      update_cache: yes

  - name: Install docker 
    yum:
      name: docker
      state: latest

  - name: Enable Docker CE service at startup
    service:
      name: docker
      state: started
      enabled: yes

  - name: Install python 
    yum:
      name: python3
      state: latest

  - name: install pip3
    yum:
      name: python3-pip
      state: latest

  - name: install docker module
    pip: 
      name: docker
      state: latest

  - name: Create a container
    docker_container:
      name: rabbitmq
      image: rabbitmq:3.8.9-management-alpine
      state: started
      restart: yes
      ports:
        - "15672:15672"
        - "5672:5672"
      volumes:
        - /home/ec2-user/rabbitmq.config:/etc/rabbitmq/rabbitmq.config
        - /home/ec2-user/definitions.json:/etc/rabbitmq/definitions.json
    vars:
      ansible_python_interpreter: /usr/bin/python3
    
    - name: remove guest user
      community.docker.docker_container_exec:
        container: rabbitmq
        command: rabbitmqctl delete_user guest
      register: result

    - name: Print stdout
      debug:
        var: result.stdout

    - rabbitmq_user:
      user: joe
      password: changeme
      vhost: /
      configure_priv: .*
      read_priv: .*
      write_priv: .*
      state: present



#  - name: create queue
#    community.rabbitmq.rabbitmq_queue:
#      name: myQueue
#      login_user: guest
#      login_password: guest
#      login_host: ${aws_instance.RabbitMQ.public_ip}
#      state: present

#  - name: create rabbitmq user
#    community.rabbitmq.rabbitmq_user:
#      user: joe
#      password: changeme
#      permissions:
#        - vhost: /
#          configure_priv: .*
#          read_priv: .*
#          write_priv: .*
#      state: present

    EOF
    destination = "/home/ec2-user/playbook.yml"
  }

 provisioner "remote-exec" {
   inline = [
     "sudo yum update -y",
     "sudo yum install python3",
     "curl -O https://bootstrap.pypa.io/get-pip.py",
     "python3 get-pip.py --user",
     "export PATH=/home/ec2-user/.local/bin:$PATH",
     "pip install -U ansible",
     "sudo chmod 400 /home/ec2-user/${var.instance_key}.pem",
     "ansible-galaxy collection install community.rabbitmq",
     "ansible-playbook playbook.yml -i inventory"
    ]
  }

  tags = {
    Name = "ansible_instance"
  }

  volume_tags = {
    Name = "ansible_instance"
  } 

  depends_on = [ aws_instance.RabbitMQ ]

}

############################################################
######### VM Resources  ####################################
resource "aws_security_group" "sg_rabbitMQ" {
  name        = "allow_ssh_rabbitMQ"
  description = "Allow ssh inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "5672 from VPC"
    from_port        = 5672
    to_port          = 5672
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "15672 from VPC"
    from_port        = 15672
    to_port          = 15672
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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

resource "aws_instance" "RabbitMQ" {
  subnet_id       = module.vpc.public_subnets[0]

  ami             = "ami-05cd35b907b4ffe77" 
  instance_type   = var.instance_type
  key_name        = var.instance_key
  security_groups = [aws_security_group.sg_rabbitMQ.id]

  connection {  
    type        = "ssh"
   	host        = self.public_ip
   	user        = "ec2-user"
   	private_key = file (var.private_key_path)
  }

  provisioner "file" {
    content = <<EOF
[
  {rabbit, [
    {loopback_users, []}
  ]},
  {rabbitmq_management, [
    {load_definitions, "/etc/rabbitmq/definitions.json"}
  ]}
].
EOF
    destination = "/home/ec2-user/rabbitmq.config"
  }

 provisioner "file" {
    content = <<EOF
{
    "users": [
      {
        "name": "user",  
        "password": "password",
        "tags": "administrator"
      }
    ],

    "vhosts":[
        {"name":"/"}
    ],
	
	"permissions": [
	 {
	  "user": "user",
	  "vhost": "/",
	  "configure": ".*",
	  "write": ".*",
	  "read": ".*"
	 }
	],
	"bindings":[
      {
         "arguments":{
            
         },
         "destination":"AddSession.dlq",
         "destination_type":"queue",
         "routing_key":"",
         "source":"AddSession.dlx",
         "vhost":"/"
      }
   ],
   "exchanges":[
      {
         "arguments":{
            
         },
         "auto_delete":false,
         "durable":true,
         "name":"AddSession.DeadLetterExchange",
         "type":"fanout",
         "vhost":"/"
      }
   ],
   "queues":[
      {
         "arguments":{
            "x-queue-type":"classic"
         },
         "auto_delete":false,
         "durable":true,
         "name":"AddSession.DeadLetterQueue",
         "type":"classic",
         "vhost":"/"
      },
      {
         "arguments":{
            "x-dead-letter-exchange":"AddSession.DeadLetterExchange",
            "x-queue-type":"classic"
         },
         "auto_delete":false,
         "durable":true,
         "name":"AddSession.Queue",
         "type":"classic",
         "vhost":"/"
      }
   ]    
}
 EOF
    destination = "/home/ec2-user/definitions.json"
  }

  tags = merge (local.common_tags, {Name = "${var.environment_tag}-RabbitMQ"})

}

############################################################
######### VM Resources  ####################################
#resource "aws_instance" "VM" {
#  count           = var.instance_count
#  subnet_id       = module.vpc.private_subnets[0]
#
#  ami             = "ami-05cd35b907b4ffe77" 
#  instance_type   = var.instance_type
#  key_name        = var.instance_key
#  security_groups = [aws_security_group.sg.id]
#
##  user_data = <<-EOF
##  #!/bin/bash
##  sudo yum update -y
##  sudo amazon-linux-extras install docker
##  sudo service docker start
##  sudo docker run -d -p 80:80 -name nginx nginx
##  EOF
#
##  connection {  
##    type        = "ssh"
##   	host        = self.public_ip
##   	user        = "ec2-user"
##   	private_key = file (var.private_key_path)
##  }
#
##  user_data = <<-EOF
##  #!/bin/bash
##  sudo yum update -y
##  sudo amazon-linux-extras install docker
##  sudo service docker start
##  sudo docker run -d -p 80:80 -name nginx nginx
##  EOF
#
##  provisioner "remote-exec" {
##    inline = [
##      "sudo yum update -y",
##      "sudo yum install python38",
##      "python3 --version",
##      "curl -O https://bootstrap.pypa.io/get-pip.py",
##      "python3 get-pip.py --user",
##      "export PATH=/home/ec2-user/.local/bin:$PATH",
##      "pip3 --version",
##      "pip install ansible",
##      "ansible --version"
##    ]
##  }
#
#  tags = merge (local.common_tags, {Name = "${var.environment_tag}-vm${count.index + 1}"})
#
#}

