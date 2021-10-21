
output "ansible_instance_ip" {
    value = aws_instance.ansible.public_ip
}

output "rabbitmq_instance_ip" {
    value = aws_instance.RabbitMQ.public_ip
}

#output "vm_instance_ip" {
#    value = aws_instance.VM[*].private_ip
#}