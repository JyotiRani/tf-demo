# ============================================================================
# AWS Infrastructure Terraform Configuration
# ============================================================================
# This configuration provisions:
# - VPC with public subnet
# - EC2 instance (t2.micro) with Amazon Linux 2023
# - 20 GB EBS volume
# - IAM role for Session Manager access
# - Security group for outbound connectivity
# - NO public IP (access via Session Manager)
# ============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
