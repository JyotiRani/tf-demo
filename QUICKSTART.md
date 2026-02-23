# Quick Start Guide

Get your AWS infrastructure up and running in 5 minutes!

## Prerequisites Check

```bash
# Check AWS CLI
aws --version
aws sts get-caller-identity

# Check Terraform
terraform --version
```

## Deploy in 4 Steps

### 1️⃣ Initialize Terraform
```bash
cd aws-infrastructure
terraform init
```

### 2️⃣ Review What Will Be Created
```bash
terraform plan
```

### 3️⃣ Deploy Infrastructure
```bash
terraform apply
```
Type `yes` when prompted.

### 4️⃣ Connect to Your Instance

**Option A: AWS Console**
1. Go to [EC2 Console](https://console.aws.amazon.com/ec2/)
2. Select your instance
3. Click **Connect** → **Session Manager** → **Connect**

**Option B: AWS CLI**
```bash
# Get the connection command from outputs
terraform output session_manager_connection_command

# Or connect directly
aws ssm start-session --target $(terraform output -raw instance_id)
```

## What You Get

✅ VPC with public subnet  
✅ EC2 t2.micro instance (Amazon Linux 2023)  
✅ 20 GB EBS volume  
✅ Session Manager access (no SSH keys needed)  
✅ **$0.00/month cost** during AWS Free Tier  

## Mount the EBS Volume

After connecting to your instance:

```bash
# Format and mount (first time only)
sudo mkfs -t ext4 /dev/sdf
sudo mkdir /data
sudo mount /dev/sdf /data
sudo chown ec2-user:ec2-user /data

# Make permanent
echo '/dev/sdf /data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
```

## Cleanup

When you're done:

```bash
terraform destroy
```

Type `yes` to confirm deletion of all resources.

## Need Help?

- See [README.md](README.md) for detailed documentation
- Check [Troubleshooting](#troubleshooting) section in README
- Review AWS Free Tier limits: https://aws.amazon.com/free/

## Cost Monitoring

Set up a billing alarm:

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name billing-alarm \
  --alarm-description "Alert when charges exceed $5" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

---

**That's it! You're ready to go! 🚀**