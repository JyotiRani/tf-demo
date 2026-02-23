# ============================================================================
# Terraform Variables
# ============================================================================
# This file defines all configurable parameters for the infrastructure
# ============================================================================

# ============================================================================
# AWS Credentials
# ============================================================================

variable "aws_access_key" {
  description = "AWS Access Key ID for authentication"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.aws_access_key) > 0
    error_message = "AWS Access Key cannot be empty."
  }
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key for authentication"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.aws_secret_key) > 0
    error_message = "AWS Secret Key cannot be empty."
  }
}

# ============================================================================
# AWS Region Configuration
# ============================================================================

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be in the format: us-east-1, eu-west-1, etc."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zone" {
  description = "Availability zone for the subnet and EBS volume"
  type        = string
  default     = "us-east-1a"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}[a-z]{1}$", var.availability_zone))
    error_message = "Availability zone must be in the format: us-east-1a, eu-west-1b, etc."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = can(regex("^t[2-3]\\.(nano|micro|small|medium|large)$", var.instance_type))
    error_message = "Instance type must be a valid t2 or t3 instance type (e.g., t2.micro, t3.small)."
  }
}

variable "ebs_volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.ebs_volume_size >= 1 && var.ebs_volume_size <= 16384
    error_message = "EBS volume size must be between 1 and 16384 GB."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "aws-infrastructure"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

# ============================================================================
# Optional Variables
# ============================================================================

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for Session Manager (reduces data transfer costs)"
  type        = bool
  default     = false
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for EC2 instance"
  type        = bool
  default     = false
}

variable "ebs_volume_type" {
  description = "EBS volume type (gp3, gp2, io1, io2, st1, sc1)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2", "st1", "sc1"], var.ebs_volume_type)
    error_message = "EBS volume type must be one of: gp3, gp2, io1, io2, st1, sc1."
  }
}

variable "enable_ebs_encryption" {
  description = "Enable encryption for EBS volumes"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}