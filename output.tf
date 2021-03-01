output "id" {
  description = "Bastion Instance ID"
  value       = aws_instance.Bastion.id
}

output "key_name" {
  description = "List of key names of instances"
  value       = aws_key_pair.instance-key.key_name
}

output "public_dns" {
  description = "DNS hostnames for Bastion"
  value       = aws_instance.Bastion.public_dns
}

output "public_ip" {
  description = "List of public IP addresses assigned to the instances, if applicable"
  value       = aws_instance.Bastion.public_ip
}

output "security_groups" {
  description = "List of associated security groups of instances"
  value       = aws_security_group.allow_http.name
}

output "elb_dns_name" {
  value = aws_elb.web_elb.dns_name
}
