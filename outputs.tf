# ============================================================================
# Terraform Outputs
# ============================================================================
# This file defines outputs that will be displayed after terraform apply
# ============================================================================

# ============================================================================
# VPC Outputs
# ============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# ============================================================================
# Subnet Outputs
# ============================================================================

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = aws_subnet.public.cidr_block
}

output "availability_zone" {
  description = "Availability zone of the subnet"
  value       = aws_subnet.public.availability_zone
}

# ============================================================================
# Security Group Outputs
# ============================================================================

output "security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2_sg.id
}

output "security_group_name" {
  description = "Name of the EC2 security group"
  value       = aws_security_group.ec2_sg.name
}

# ============================================================================
# IAM Outputs
# ============================================================================

output "iam_role_name" {
  description = "Name of the IAM role for Session Manager"
  value       = aws_iam_role.ec2_ssm_role.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role for Session Manager"
  value       = aws_iam_role.ec2_ssm_role.arn
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

# ============================================================================
# EC2 Instance Outputs
# ============================================================================

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.main.arn
}

output "instance_type" {
  description = "Instance type of the EC2 instance"
  value       = aws_instance.main.instance_type
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.main.instance_state
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "instance_private_dns" {
  description = "Private DNS name of the EC2 instance"
  value       = aws_instance.main.private_dns
}

output "ami_id" {
  description = "AMI ID used for the EC2 instance"
  value       = aws_instance.main.ami
}

output "ami_name" {
  description = "Name of the AMI used"
  value       = data.aws_ami.amazon_linux_2023.name
}

# ============================================================================
# EBS Volume Outputs
# ============================================================================

output "ebs_volume_id" {
  description = "ID of the EBS data volume"
  value       = aws_ebs_volume.data.id
}

output "ebs_volume_arn" {
  description = "ARN of the EBS data volume"
  value       = aws_ebs_volume.data.arn
}

output "ebs_volume_size" {
  description = "Size of the EBS volume in GB"
  value       = aws_ebs_volume.data.size
}

output "ebs_volume_type" {
  description = "Type of the EBS volume"
  value       = aws_ebs_volume.data.type
}

output "ebs_device_name" {
  description = "Device name of the attached EBS volume"
  value       = aws_volume_attachment.data_attachment.device_name
}

# ============================================================================
# Connection Information
# ============================================================================

output "session_manager_connection_command" {
  description = "AWS CLI command to connect via Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.main.id} --region ${var.aws_region}"
}

output "session_manager_console_url" {
  description = "AWS Console URL to connect via Session Manager"
  value       = "https://${var.aws_region}.console.aws.amazon.com/ec2/v2/home?region=${var.aws_region}#ConnectToInstance:instanceId=${aws_instance.main.id}"
}

# ============================================================================
# Summary Output
# ============================================================================

output "infrastructure_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    region             = var.aws_region
    vpc_id             = aws_vpc.main.id
    subnet_id          = aws_subnet.public.id
    instance_id        = aws_instance.main.id
    instance_type      = aws_instance.main.instance_type
    private_ip         = aws_instance.main.private_ip
    ebs_volume_id      = aws_ebs_volume.data.id
    ebs_volume_size_gb = aws_ebs_volume.data.size
    ami_name           = data.aws_ami.amazon_linux_2023.name
    access_method      = "AWS Systems Manager Session Manager"
  }
}

# ============================================================================
# Quick Start Commands
# ============================================================================

output "quick_start_commands" {
  description = "Quick start commands for common tasks"
  value = {
    connect_via_cli  = "aws ssm start-session --target ${aws_instance.main.id}"
    mount_ebs_volume = "sudo mkfs -t ext4 /dev/sdf && sudo mkdir /data && sudo mount /dev/sdf /data"
    check_instance   = "aws ec2 describe-instances --instance-ids ${aws_instance.main.id}"
    check_ssm_status = "aws ssm describe-instance-information --filters Key=InstanceIds,Values=${aws_instance.main.id}"
    vault_status     = "vault status"
    vault_logs       = "journalctl -u vault -f"
    view_vault_keys  = "sudo cat /root/vault-init.txt"
  }
}

# ============================================================================
# HashiCorp Vault Outputs
# ============================================================================

output "vault_information" {
  description = "HashiCorp Vault server information"
  value = {
    vault_address        = "http://127.0.0.1:8200 (internal only)"
    vault_status_command = "vault status"
    vault_ui_access      = "Not accessible externally (no public IP)"
    vault_keys_location  = "/root/vault-init.txt (SECURE THIS FILE!)"
    vault_service_status = "systemctl status vault"
    vault_logs_command   = "journalctl -u vault -f"
    important_note       = "Vault is initialized and unsealed. Root token and unseal keys are in /root/vault-init.txt"
  }
}

# ============================================================================
# Cost Information
# ============================================================================

output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    ec2_instance     = "Free Tier: $0.00 (750 hrs/month) | After: ~$8.50/month"
    ebs_root_volume  = "Free Tier: $0.00 (within 30 GB) | After: ~$0.80/month"
    ebs_data_volume  = "Free Tier: $0.00 (within 30 GB) | After: ~$2.00/month"
    networking       = "Always Free: $0.00"
    total_free_tier  = "$0.00/month"
    total_after_12mo = "~$11.30/month"
  }
}