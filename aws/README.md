# Terraform

Here you can find some examples.

- The first one deploy VPC, two subnets, two machines with NGINX, a ELB and a bucket to storage logs and initial web. With this script will be deploy an infrastructure using environment variables to connect
- The second one uses an aws profile and modules to deploy the VPC
- The third one uses consul to storage the terraform state and configuration
- **Ansible**: there are provisioned one Ansible control machine and other VM that is configured with Ansible deploying a docker image
- **Web**: Deploy a load balancer and two virtual machines, the app is deploy as docker image
