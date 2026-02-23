# AWS Infrastructure with Terraform

Complete Terraform configuration to provision AWS infrastructure based on the architecture diagram, featuring EC2 instance with Session Manager access, VPC, and EBS storage done .

## 🏗️ Architecture Overview

This Terraform configuration creates:

- **VPC** (10.0.0.0/16) with DNS support
- **Public Subnet** (10.0.1.0/24) in Availability Zone A
- **Internet Gateway** for outbound connectivity
- **Security Group** with HTTPS egress for Session Manager
- **EC2 Instance** (t2.micro) with Amazon Linux 2023
- **EBS Volume** (20 GB gp3) for data storage
- **IAM Role** for AWS Systems Manager Session Manager access
- **NO Public IP** - Secure access via Session Manager only

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Region: us-east-1                     │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              VPC: 10.0.0.0/16                         │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │    Availability Zone: us-east-1a                │  │  │
│  │  │  ┌───────────────────────────────────────────┐  │  │  │
│  │  │  │  Public Subnet: 10.0.1.0/24              │  │  │  │
│  │  │  │  ┌────────────────────────────────────┐  │  │  │  │
│  │  │  │  │  Security Group                    │  │  │  │  │
│  │  │  │  │  - HTTPS Egress (443)              │  │  │  │  │
│  │  │  │  └────────────────────────────────────┘  │  │  │  │
│  │  │  │  ┌────────────────────────────────────┐  │  │  │  │
│  │  │  │  │  EC2 Instance (t2.micro)           │  │  │  │  │
│  │  │  │  │  - Amazon Linux 2023               │  │  │  │  │
│  │  │  │  │  - No Public IP                    │  │  │  │  │
│  │  │  │  │  - IAM Role for Session Manager    │  │  │  │  │
│  │  │  │  └────────────────────────────────────┘  │  │  │  │
│  │  │  │  ┌────────────────────────────────────┐  │  │  │  │
│  │  │  │  │  EBS Volume (20 GB gp3)            │  │  │  │  │
│  │  │  │  └────────────────────────────────────┘  │  │  │  │
│  │  │  └───────────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │  Internet Gateway ──────────────────────────────────▶ │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
   AWS Systems Manager
   Session Manager
```

## 💰 Cost Analysis

### During Free Tier (First 12 Months)
- **EC2 t2.micro**: $0.00 (750 hours/month included)
- **EBS Storage (28 GB total)**: $0.00 (30 GB included)
- **VPC & Networking**: $0.00 (Always free)
- **Session Manager**: $0.00 (Always free)
- **NO Public IP**: $0.00 (Removed to avoid charges)

**Total: $0.00/month** 🎉

### After Free Tier (12+ Months)
- **EC2 t2.micro**: ~$8.50/month
- **EBS Root Volume (8 GB)**: ~$0.80/month
- **EBS Data Volume (20 GB)**: ~$2.00/month
- **VPC & Networking**: $0.00 (Always free)

**Total: ~$11.30/month**

## 📋 Prerequisites

Before you begin, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
   ```bash
   aws --version
   aws configure
   ```
3. **Terraform** installed (version >= 1.0)
   ```bash
   terraform --version
   ```
4. **Session Manager Plugin** (for CLI access)
   - [Installation Guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

## 🚀 Quick Start

### Step 1: Clone or Download

```bash
# Navigate to the aws-infrastructure directory
cd aws-infrastructure
```

### Step 2: Configure Variables (Optional)

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your preferred values (optional - defaults work fine)
notepad terraform.tfvars  # Windows
nano terraform.tfvars     # Linux/Mac
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This will:
- Download the AWS provider plugin
- Initialize the backend
- Prepare the working directory

### Step 4: Review the Plan

```bash
terraform plan
```

This shows what resources will be created without making any changes.

### Step 5: Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### Step 6: Access Your Instance

After deployment completes, you'll see outputs including connection commands.

#### Option A: AWS Console (Easiest)
1. Go to [EC2 Console](https://console.aws.amazon.com/ec2/)
2. Select your instance
3. Click **Connect** button
4. Choose **Session Manager** tab
5. Click **Connect**

#### Option B: AWS CLI
```bash
# Get instance ID from outputs
terraform output instance_id

# Connect via Session Manager
aws ssm start-session --target <instance-id>
```

#### Option C: Direct Command (from outputs)
```bash
# Copy the command from terraform outputs
terraform output session_manager_connection_command
```

## 📦 What Gets Created

| Resource | Name/ID | Description |
|----------|---------|-------------|
| VPC | `aws-infrastructure-vpc` | Virtual Private Cloud (10.0.0.0/16) |
| Subnet | `aws-infrastructure-public-subnet` | Public subnet (10.0.1.0/24) |
| Internet Gateway | `aws-infrastructure-igw` | Internet connectivity |
| Route Table | `aws-infrastructure-public-rt` | Routes traffic to IGW |
| Security Group | `aws-infrastructure-ec2-sg` | Firewall rules |
| IAM Role | `aws-infrastructure-ec2-ssm-role` | Session Manager permissions |
| EC2 Instance | `aws-infrastructure-ec2-instance` | t2.micro with Amazon Linux 2023 |
| EBS Volume | `aws-infrastructure-data-volume` | 20 GB gp3 storage |

## 🔧 Post-Deployment Tasks

### Mount the EBS Volume

After connecting to your instance via Session Manager:

```bash
# Check available disks
lsblk

# Format the volume (only needed once)
sudo mkfs -t ext4 /dev/sdf

# Create mount point
sudo mkdir /data

# Mount the volume
sudo mount /dev/sdf /data

# Change ownership
sudo chown ec2-user:ec2-user /data

# Make mount permanent (survives reboots)
echo '/dev/sdf /data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab

# Verify
df -h /data
```

### Install Additional Software

```bash
# Update system
sudo dnf update -y

# Install development tools
sudo dnf groupinstall "Development Tools" -y

# Install Docker
sudo dnf install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install Python 3
sudo dnf install python3 python3-pip -y

# Install Node.js
sudo dnf install nodejs npm -y
```

## 📊 Useful Commands

### Terraform Commands

```bash
# Show current state
terraform show

# List all resources
terraform state list

# Show specific resource
terraform state show aws_instance.main

# View outputs
terraform output

# View specific output
terraform output instance_id

# Format code
terraform fmt

# Validate configuration
terraform validate

# Refresh state
terraform refresh

# Destroy infrastructure
terraform destroy
```

### AWS CLI Commands

```bash
# Check instance status
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)

# Check Session Manager connectivity
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$(terraform output -raw instance_id)"

# List EBS volumes
aws ec2 describe-volumes --filters "Name=tag:Name,Values=aws-infrastructure-data-volume"

# Check VPC details
aws ec2 describe-vpcs --vpc-ids $(terraform output -raw vpc_id)
```

### Instance Commands (via Session Manager)

```bash
# Check system information
hostnamectl
uname -a

# Check disk usage
df -h

# Check memory usage
free -h

# Check running processes
top

# Check network configuration
ip addr show

# Check mounted volumes
mount | grep /data

# View system logs
sudo journalctl -xe

# Check SSM agent status
sudo systemctl status amazon-ssm-agent
```

## 🔐 Security Features

### Built-in Security

✅ **No Public IP Address**
- Instance is not directly accessible from the internet
- Reduces attack surface significantly

✅ **Session Manager Access**
- Encrypted connections via AWS Systems Manager
- No SSH keys to manage
- All sessions logged in CloudTrail

✅ **EBS Encryption**
- All volumes encrypted at rest
- Uses AWS-managed keys

✅ **Security Group**
- Only HTTPS egress allowed
- No inbound rules (Session Manager doesn't need them)

✅ **IAM Role-Based Access**
- Fine-grained permissions
- No long-term credentials on instance

### Additional Security Recommendations

```bash
# Enable CloudTrail (if not already enabled)
aws cloudtrail create-trail --name my-trail --s3-bucket-name my-bucket

# Enable VPC Flow Logs
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids $(terraform output -raw vpc_id) \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name /aws/vpc/flowlogs

# Enable AWS Config
aws configservice put-configuration-recorder --configuration-recorder name=default,roleARN=arn:aws:iam::ACCOUNT:role/config-role

# Set up billing alerts
aws cloudwatch put-metric-alarm \
  --alarm-name billing-alarm \
  --alarm-description "Alert when charges exceed $10" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

## 🐛 Troubleshooting

### Issue: Cannot connect via Session Manager

**Solution:**
```bash
# 1. Check if SSM agent is running
aws ssm describe-instance-information

# 2. Verify IAM role is attached
aws ec2 describe-instances --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].IamInstanceProfile'

# 3. Check security group allows HTTPS egress
aws ec2 describe-security-groups --group-ids <sg-id>

# 4. Restart SSM agent (via EC2 console > Actions > Monitor and troubleshoot > Get system log)
```

### Issue: EBS volume not visible

**Solution:**
```bash
# Connect to instance and check
lsblk

# If not visible, check attachment
aws ec2 describe-volumes --volume-ids <volume-id>

# Reattach if needed
terraform apply -replace=aws_volume_attachment.data_attachment
```

### Issue: Terraform state locked

**Solution:**
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Issue: Free tier exceeded

**Solution:**
```bash
# Check current usage
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost

# Stop instance when not in use
aws ec2 stop-instances --instance-ids <instance-id>

# Start instance when needed
aws ec2 start-instances --instance-ids <instance-id>
```

## 📚 Additional Resources

- [AWS Free Tier](https://aws.amazon.com/free/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [Amazon Linux 2023 Documentation](https://docs.aws.amazon.com/linux/al2023/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## 🧹 Cleanup

To destroy all resources and avoid charges:

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Type 'yes' when prompted
```

**Note:** This will permanently delete all resources including the EBS volume and any data stored on it.

## 📝 File Structure

```
aws-infrastructure/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfvars.example   # Example variable values
├── README.md                  # This file
├── .terraform/                # Terraform working directory (auto-generated)
├── terraform.tfstate          # Terraform state file (auto-generated)
└── terraform.tfstate.backup   # State backup (auto-generated)
```

## 🤝 Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## 📄 License

This project is provided as-is for educational and demonstration purposes.

## ⚠️ Important Notes

1. **Free Tier**: Monitor your usage to stay within free tier limits
2. **Security**: Never commit `terraform.tfvars` or state files to version control
3. **Costs**: Always destroy resources when not in use to avoid charges
4. **Backups**: Regularly backup important data from the EBS volume
5. **Updates**: Keep Terraform and AWS provider up to date

## 🎯 Next Steps

After deploying this infrastructure, you can:

1. Install and configure your applications
2. Set up automated backups for the EBS volume
3. Configure CloudWatch alarms for monitoring
4. Implement auto-scaling (requires additional configuration)
5. Add a load balancer for high availability
6. Set up CI/CD pipelines for deployments

---

**Created with ❤️ using Terraform**

For questions or support, please open an issue in the repository.