# SPDX-License-Identifier: Apache-2.0

output "dtrack_ec2_instance_id" {
  description = "The ID of the EC2 instance for OWASP Dependency Track."
  value       = module.component_analysis.ec2_instance_id
}

output "dtrack_ec2_private_ip" {
  description = "The private IP address of the EC2 instance for OWASP Dependency Track."
  value       = module.component_analysis.ec2_private_ip
}

output "dtrack_ec2_public_ip" {
  description = "The public IP address of the EC2 instance for OWASP Dependency Track."
  value       = module.component_analysis.ec2_public_ip
}

output "dtrack_ec2_public_dns" {
  description = "The public DNS of the EC2 instance for OWASP Dependency Track."
  value       = module.component_analysis.ec2_public_dns
}
