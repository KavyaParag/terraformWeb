# terraformWeb
Setting up a scalable, fault tolerant web server architecture
EC2 instance with EBS volume attachment

Configuration in this directory creates EC2 instances, EBS volume and attach it together.

Unspecified arguments for security group id and subnet are inherited from the default VPC.

This example outputs instance id and EBS volume id.
Usage

To run this example you need to execute:

$ terraform init
$ terraform plan
$ terraform apply

Note that this example may create resources which can cost money. Run terraform destroy when you don't need these resources.

Requirements
Name 	Version
terraform 	>= 0.12.6
aws 	>= 2.65

Providers
Name 	Version
aws 	>= 2.65

Resources
Name
aws_ami
aws_ebs_volume
aws_subnet_ids
aws_volume_attachment
aws_vpc
Inputs
Name 	Description 	Type 	Default 	Required
instances_number 	NUmber of instances 	number 	1 	no

Outputs
Name 	Description
instances_public_ips 	Public IPs assigned to the EC2 instance
