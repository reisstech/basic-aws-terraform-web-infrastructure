# Deploying a Basic AWS Web Infrastructure using Terraform

This is a personal project where I built a basic infrastructure on AWS using Terraform.

Below is a simple diagram of the infrastructure:


![Preview-Screens](https://github.com/reisstech/basic-aws-terraform-web-infrastructure/blob/main/diagram.png)

The entire infrastructure was built in on a non-default VPC.

In this project I had to create the following resources in AWS

- 1 VPC
- 2 Subnets
- 2 Instances
- 1 Internet Gateway
- 1 Route Table
- 1 Key Pair
- 2 Security Group (One for the Instances and one for the Load Balancer)
- 1 Target Group
- 1 Listener
