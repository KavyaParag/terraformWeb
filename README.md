# AWS Web Application Infrastructure using Terraform

A simple web application is created on AWS using Terraform

# Usage
```sh
$ terraform init
$ terraform plan
$ terraform apply
```
# Requirements
```sh
terraform > 0.12
aws >= 3.27
```
## Web Architecture Design Principles

- It must include a VPC which enables future growth / scale
```sh
    VPC -- ap-south-1 (Mumbai) -- 10.0.0.0/16 --  65,536 Usable IPs
```
> The architecture is designed with a VPC of CIDR block 10.0.0.0/16, which allows a space of 65,536 IPs
>The VPC is designed with the scope for future growth and scaling.
    The region for the web servers is selected as per the location of the end users --> South Asia (Mumbai region)
    
- It must include both a public and private subnet - where the private subnet is used for compute and the public is used for the load balancers
```sh
    Public subnet 1 -- ap-south-1a -- 10.0.0.0/24 -- 251 Usable IPs
    Public subnet 2 -- ap-south-1b -- 10.0.0.1/24 -- 251 Usable IPs
    
    Private subnet 1 -- ap-south-1a -- 10.0.0.2/24 -- 251 Usable IPs
    Private subnet 2 -- ap-south-1b -- 10.0.0.3/24 -- 251 Usable IPs
```
>   The VPC is further divided into 4 subnets, 2 public and 2 private subnets, that span the availability zones of us-east-1a and us-east-1b.
The Private subnet has connectivity to the internet using a NAT gateway
    The NAT gateway is launched in the public subnet with an Elastic IP associated with it.
    The Private subnet route has an association with the NAT gateway.

- Assuming that end-users only contact the load balancers and the underlying instances
are accessed for management purposes, design a security group scheme which supports the minimal set of ports required for communication
```sh
    End users --> Load balancer (Port:80) --> Web server 1, Web server 2 (Port:80)
    Management team--> Bastion Host (Port:3389) --> Web 1, Web  2 (Port:22)
```
>   For the end users,the traffic is limited and allowed only via the the load balancers
    Hence, the webport is open across the web (0.0.0.0/0) from the elb
    
>   For the management team instances, only the SSH and RDP ports are allowed
    The webport on the instance is referenced using the load balancer security group
    
- The AWS generated load balancer hostname will be used for requests to the public facing web application
```sh
End users --> Load Balancer DNS name
```
> The web servers can be accessed only via the classic load balacers which are internet facing and reside in the public subnet.

- An autoscaling group should be created which utilizes the latest AWS AMI
    • Instances in the ASG
        ◦ must contain both a root volume to store the application / services
        ◦ must contain a secondary volume meant to store any log data bound for /var/log
        ◦ must include a web server of your choice
>  The autoscaling group is created using a Launch Configuration that includes an AWS AMI.
    The instances launched from the autoscaling group are launched in the private subnet.

>    The user data holds the necessary script required to launch the web server along with partioned volumes for logs.

> A bastion instance is launched in the private subnet that allows connectivity to the web servers in the private subnet

## Additional Points Covered:
- You should design these web servers so they can be managed without logging in with the root key
> This point could not be covered due to time constraints
But, this can be achieved by installing the Systems Manager agent on the instance.
SSM can then be used to access these instances without reuiring the root key.

-   We should have some sort of alarm mechanism that indicates when the application is
experiencing any issues
> An alarm is configured to alert the team incase the CPU threshold crosses 70%.
This alarm is incorportaed in the scaling policy of the Auto Scaling Group.

-   Configure the autoscaling group to automatically add and remove nodes based on load
> A scaling policy has been setup that adds/removes nodes based on the CPU utilization of the web servers.

-   You should assume that this web server may receive high volumes of web traffic, thus you should appropriately manage the storage / growth of logs
> Log rotate has been configured on the web servers for managing growth of logs in future scenarios.
