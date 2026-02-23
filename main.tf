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

# ============================================================================
# Provider Configuration
# ============================================================================

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "development"
      ManagedBy   = "Terraform"
    }
  }
}

# ============================================================================
# Data Sources
# ============================================================================

# Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# ============================================================================
# VPC Resources
# ============================================================================

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Create Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false # No public IP assignment

  tags = {
    Name = "${var.project_name}-public-subnet"
    Type = "Public"
  }
}

# Create Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ============================================================================
# Security Group
# ============================================================================

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instance with Session Manager access"
  vpc_id      = aws_vpc.main.id

  # Egress rule for HTTPS (required for Session Manager)
  egress {
    description = "HTTPS to Session Manager endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule for all traffic (for updates and package installation)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# ============================================================================
# IAM Role for Session Manager
# ============================================================================

# IAM Role
resource "aws_iam_role" "ec2_ssm_role" {
  name        = "${var.project_name}-ec2-ssm-role"
  description = "IAM role for EC2 to use Session Manager"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-ssm-role"
  }
}

# Attach AWS managed policy for Session Manager
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name

  tags = {
    Name = "${var.project_name}-ec2-profile"
  }
}

# ============================================================================
# EC2 Instance
# ============================================================================

resource "aws_instance" "main" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # Disable public IP assignment
  associate_public_ip_address = false

  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = false

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  # User data script to install SSM agent and HashiCorp Vault
  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # Log all output
              exec > >(tee /var/log/user-data.log)
              exec 2>&1
              
              echo "Starting user data script..."
              
              # Update system packages
              dnf update -y
              
              # Ensure SSM agent is running
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              
              # Install useful tools
              dnf install -y htop tree wget curl unzip jq
              
              # Install HashiCorp Vault
              echo "Installing HashiCorp Vault..."
              
              # Add HashiCorp repository
              dnf install -y dnf-plugins-core
              dnf config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
              
              # Install Vault
              dnf install -y vault
              
              # Create Vault configuration directory
              mkdir -p /etc/vault.d
              chmod 700 /etc/vault.d
              
              # Create Vault data directory
              mkdir -p /opt/vault/data
              chmod 700 /opt/vault/data
              
              # Create Vault configuration file
              cat > /etc/vault.d/vault.hcl << 'VAULTCONFIG'
              ui = true
              
              storage "file" {
                path = "/opt/vault/data"
              }
              
              listener "tcp" {
                address     = "0.0.0.0:8200"
                tls_disable = 1
              }
              
              api_addr = "http://127.0.0.1:8200"
              cluster_addr = "http://127.0.0.1:8201"
              VAULTCONFIG
              
              # Set proper permissions
              chown -R vault:vault /etc/vault.d
              chown -R vault:vault /opt/vault
              
              # Create systemd service file
              cat > /etc/systemd/system/vault.service << 'VAULTSERVICE'
              [Unit]
              Description=HashiCorp Vault
              Documentation=https://www.vaultproject.io/docs/
              Requires=network-online.target
              After=network-online.target
              ConditionFileNotEmpty=/etc/vault.d/vault.hcl
              
              [Service]
              User=vault
              Group=vault
              ProtectSystem=full
              ProtectHome=read-only
              PrivateTmp=yes
              PrivateDevices=yes
              SecureBits=keep-caps
              AmbientCapabilities=CAP_IPC_LOCK
              Capabilities=CAP_IPC_LOCK+ep
              CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
              NoNewPrivileges=yes
              ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
              ExecReload=/bin/kill --signal HUP $MAINPID
              KillMode=process
              KillSignal=SIGINT
              Restart=on-failure
              RestartSec=5
              TimeoutStopSec=30
              LimitNOFILE=65536
              LimitMEMLOCK=infinity
              
              [Install]
              WantedBy=multi-user.target
              VAULTSERVICE
              
              # Enable and start Vault service
              systemctl daemon-reload
              systemctl enable vault
              systemctl start vault
              
              # Wait for Vault to start
              sleep 10
              
              # Set Vault address for CLI
              export VAULT_ADDR='http://127.0.0.1:8200'
              echo "export VAULT_ADDR='http://127.0.0.1:8200'" >> /etc/profile.d/vault.sh
              
              # Initialize Vault and save keys
              echo "Initializing Vault..."
              vault operator init -key-shares=5 -key-threshold=3 > /root/vault-init.txt
              chmod 600 /root/vault-init.txt
              
              # Extract unseal keys and root token
              UNSEAL_KEY_1=$(grep 'Unseal Key 1:' /root/vault-init.txt | awk '{print $NF}')
              UNSEAL_KEY_2=$(grep 'Unseal Key 2:' /root/vault-init.txt | awk '{print $NF}')
              UNSEAL_KEY_3=$(grep 'Unseal Key 3:' /root/vault-init.txt | awk '{print $NF}')
              ROOT_TOKEN=$(grep 'Initial Root Token:' /root/vault-init.txt | awk '{print $NF}')
              
              # Unseal Vault
              echo "Unsealing Vault..."
              vault operator unseal $UNSEAL_KEY_1
              vault operator unseal $UNSEAL_KEY_2
              vault operator unseal $UNSEAL_KEY_3
              
              # Login with root token
              vault login $ROOT_TOKEN
              
              # Enable KV secrets engine
              vault secrets enable -version=2 kv
              
              # Create a sample secret
              vault kv put kv/demo username="admin" password="changeme"
              
              # Create a welcome message
              cat > /etc/motd << 'MOTD'
              ================================================
              Welcome to AWS Infrastructure EC2 Instance
              ================================================
              Instance Type: t2.micro
              OS: Amazon Linux 2023
              Access: AWS Systems Manager Session Manager
              
              HashiCorp Vault Status:
              - Vault Address: http://127.0.0.1:8200
              - Vault UI: Not accessible externally (no public IP)
              - Vault Keys: /root/vault-init.txt (SECURE THIS!)
              - Check status: vault status
              - View logs: journalctl -u vault -f
              
              Useful Commands:
              - Check EBS volumes: lsblk
              - Mount EBS volume: See README.md
              - System info: hostnamectl
              - Vault status: vault status
              - Vault logs: journalctl -u vault
              ================================================
              MOTD
              
              echo "User data script completed successfully!"
              EOF

  tags = {
    Name = "${var.project_name}-ec2-instance"
  }

  # Ensure IAM role is created before instance
  depends_on = [
    aws_iam_role_policy_attachment.ssm_policy
  ]
}

# ============================================================================
# EBS Volume
# ============================================================================

resource "aws_ebs_volume" "data" {
  availability_zone = var.availability_zone
  size              = var.ebs_volume_size
  type              = "gp3"
  encrypted         = false

  tags = {
    Name = "${var.project_name}-data-volume"
  }
}

# Attach EBS Volume to EC2 Instance
resource "aws_volume_attachment" "data_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.main.id

  # Prevent volume from being deleted when attachment is destroyed
  skip_destroy = false
}

# ============================================================================
# VPC Endpoints for Session Manager (Optional but recommended)
# ============================================================================
# These endpoints allow Session Manager to work without internet gateway
# Uncomment if you want to use private connectivity

# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${var.aws_region}.ssm"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = [aws_subnet.public.id]
#   security_group_ids  = [aws_security_group.ec2_sg.id]
#   private_dns_enabled = true
#
#   tags = {
#     Name = "${var.project_name}-ssm-endpoint"
#   }
# }
#
# resource "aws_vpc_endpoint" "ssmmessages" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = [aws_subnet.public.id]
#   security_group_ids  = [aws_security_group.ec2_sg.id]
#   private_dns_enabled = true
#
#   tags = {
#     Name = "${var.project_name}-ssmmessages-endpoint"
#   }
# }
#
# resource "aws_vpc_endpoint" "ec2messages" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = [aws_subnet.public.id]
#   security_group_ids  = [aws_security_group.ec2_sg.id]
#   private_dns_enabled = true
#
#   tags = {
#     Name = "${var.project_name}-ec2messages-endpoint"
#   }
# }
