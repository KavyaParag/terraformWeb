terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = "default"
  shared_credentials_file = "~/.aws/credentials"
  region  = "ap-south-1"
}	


resource "aws_vpc" "my_vpc" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "My VPC"
  }
}

#Creating a Public Subnet
resource "aws_subnet" "public_ap_south_1a" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "Public Subnet ap-south-1a"
  }
}
#Creating a public2 Subnet
resource "aws_subnet" "public2_ap_south_1b" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "public2 Subnet ap-south-1b"
  }
}
#Creating a private1 Subnet
resource "aws_subnet" "private1_ap_south_1a" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "false"
  tags = {
    Name = "private1 Subnet ap-south-1a"
  }
}
#Creating a private2 Subnet
resource "aws_subnet" "private2_ap_south_1b" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "false"
  tags = {
    Name = "private2 Subnet ap-south-1b"
  }
}
#creating an IGW
resource "aws_internet_gateway" "my_vpc_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "My VPC - Internet Gateway"
  }
}
#NAT EIP
resource "aws_eip" "nat_1" {
  vpc                       = true
}
#NAT Gateway
resource "aws_nat_gateway" "gw_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_ap_south_1a.id
  tags = {
    Name = "gw NAT 1"
  }
}
#Creating a Public RT
resource "aws_route_table" "my_vpc_public" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_vpc_igw.id
    }
    tags = {
        Name = "Public Subnets Route Table for My VPC"
    }
}
#Creating a private RT
resource "aws_route_table" "my_vpc_private" {
    vpc_id = aws_vpc.my_vpc.id
    route {
    	cidr_block = "0.0.0.0/0"
	gateway_id =aws_nat_gateway.gw_1.id
  }
    tags = {
        Name = "Private Subnets Route Table for My VPC"
    }
}
#Route table associations -- Public
resource "aws_route_table_association" "my_vpc_ap_south_1a_public" {
    subnet_id = aws_subnet.public_ap_south_1a.id
    route_table_id = aws_route_table.my_vpc_public.id
}
resource "aws_route_table_association" "my_vpc_ap_south_1b_public" {
    subnet_id = aws_subnet.public2_ap_south_1b.id
    route_table_id = aws_route_table.my_vpc_public.id
}
#Route table associations-- Private
resource "aws_route_table_association" "my_vpc_ap_south_1a_private" {
    subnet_id = aws_subnet.private1_ap_south_1a.id
    route_table_id = aws_route_table.my_vpc_private.id
}
resource "aws_route_table_association" "my_vpc_ap_south_1b_private" {
    subnet_id = aws_subnet.private2_ap_south_1b.id
    route_table_id = aws_route_table.my_vpc_private.id
}

#Sec group for bastion
resource "aws_security_group" "bastion-sg" {
  name        = "bastion-sg"
  description = "Allow RDP inbound connections"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #Respective public IP's to be used
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow bastion Security Group"
  }
}
  
#Bastion Creation
resource "aws_instance" "Bastion" {
  ami           = "ami-0fcd8d621cf9ab602"
  instance_type = "t2.large"
  subnet_id= aws_subnet.public_ap_south_1a.id
  key_name      = "${aws_key_pair.instance-key.key_name}"

  vpc_security_group_ids = [aws_security_group.bastion-sg.id]
  tags = {
    Name = "Bastion server created via terraform"
  }
}

#SEC Group for ELB
resource "aws_security_group" "elb_http" {
  name        = "elb_http"
  description = "Allow HTTP traffic to instances through Elastic Load Balancer"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP through ELB Security Group"
  }
}

#Sec group for application in private subnet
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound connections"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #Sec group of Load balancer should be referenced to limit direct access to instances
  }
  
    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.Bastion.private_ip}/32"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP Security Group"
  }

}
  



#ELB
resource "aws_elb" "web_elb" {
  name = "web-elb"
  security_groups = [aws_security_group.elb_http.id]
  subnets = [
    aws_subnet.public_ap_south_1a.id,
    aws_subnet.public2_ap_south_1b.id
  ]
  
  #instances                   = [aws_instance.busybox_web_server.id]
  cross_zone_load_balancing   = true

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 30
    interval = 60
    target = "HTTP:80/"
  }

  listener {
    lb_port = 80
    lb_protocol = "tcp"
    instance_port = "80"
    instance_protocol = "tcp"
  }

}

resource "aws_key_pair" "instance-key" {
  key_name   = "instance-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDhyh/JES9/yOSrVQBsI4UW6DfnfkxVPwfWns4UdZg7rAWs2TcjAqZByH364pW3w+s98QzaA/jliS6ErZ957fYUrmElz3UIzePyPp/rLh0pkRv7FSIrovTJQHXVdmjLh0WckFykf4OSPgAJXIubDCoc2ktJXuSmzKNhm3XVBcyvVV/G6bsWY+wW1z1LLoCkE8w8iV0QJrwnMul9p6PzQneIS6Rkvz++9lYNcdaFWnFBYPqK6G5Z3/U7hxLjs/fgWsdHyasfUqfxUzsbtGzJR9qQ8gAJUoF0nd1a+pAA+rlN5k3TWKTycjaqy0c1RWgkjJunqi83CU6ljLGVtYvKc89LYJaqo5VytAtByUBXyg5li/1b5j4oe9lJEa1ZHmnp/+Ly7rAcI0jGd+J3U8Ahe2X39G6y+i7iIcEz1DhCEQhLHlRn6VKfT9VxnKrGyYtUzmmCd5VhQr+PJgmpfGiP2/t0ZgmhdLowfUQvCxw/LvYw6Ap+k2pxUxf3l2cCO8YWLks= root@mcplmumlptlen18"
}




#### PART 2 ASG + LC

resource "aws_launch_configuration" "web" {
  name_prefix = "web-"

  image_id = "ami-073c8c0760395aab8" # Amazon Linux Ubuntu
  instance_type = "t2.micro"

  key_name      = "${aws_key_pair.instance-key.key_name}"

  security_groups = [ aws_security_group.allow_http.id ]
  #associate_public_ip_address = true
  
  ebs_block_device {
      device_name           = "/dev/xvdb"
      volume_type           = "gp2"
      volume_size           = "8"
      delete_on_termination = true
}

  user_data =   <<-EOF
		#!/bin/bash
		#Update all packages
		apt-get update -y
		#Create partition
		(
		echo o 
		echo n 
		echo p 
		echo 1 
		echo   
		echo   
		echo w 
		) | sudo fdisk /dev/xvdb 
		#Format drive
		yes | sudo mkfs -t ext4 /dev/xvdb1 
		#Mount drive
		sudo mount /dev/xvdb1 /var/log 
		#Add entry to fstab
		if ! grep -q '/dev/xvdb1' /etc/fstab ; then
		    echo '/dev/xvdb1 /var/log    ext4    defaults    0    2' >> /etc/fstab
		fi
		#Install logrotate for log management
		apt-get install logrotate -y
		#Install and start apache2 web Server
		apt-get install apache2 -y
		sudo service apache2 start
		#Update Homepage
		echo "Assignment from Mastercard for SRE Engineer by Kavya Parag" > /var/www/html/index.html
		#Restart Apache2 Server
		apt-get restart apache2
		EOF
              
  lifecycle {
    create_before_destroy = true
  }
}



#ASG

resource "aws_autoscaling_group" "web" {
  name = "${aws_launch_configuration.web.name}-asg"

  min_size             = 2
  desired_capacity     = 2
  max_size             = 3
  
  health_check_type    = "ELB"
  load_balancers = [
    aws_elb.web_elb.id
  ]

  launch_configuration = aws_launch_configuration.web.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  #metrics_granularity = "1Minute"

  vpc_zone_identifier  = [
    aws_subnet.private1_ap_south_1a.id,
    aws_subnet.private2_ap_south_1b.id
  ]

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  
  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }

}

resource "aws_autoscaling_policy" "web_policy_up" {
  name = "web_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "70"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_policy_up.arn ]
}




