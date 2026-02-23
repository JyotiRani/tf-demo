# HashiCorp Vault Setup Guide

## Overview

This Terraform configuration automatically deploys a HashiCorp Vault server on an AWS EC2 instance (t2.micro) running Amazon Linux 2023. The Vault server is configured with file storage backend and is automatically initialized and unsealed during instance launch.

## What Gets Deployed

### Infrastructure Components
- **EC2 Instance**: t2.micro with Amazon Linux 2023
- **HashiCorp Vault**: Latest version from HashiCorp repository
- **Storage**: File-based storage in `/opt/vault/data`
- **Configuration**: Located in `/etc/vault.d/vault.hcl`
- **Service**: Systemd service running as `vault` user

### Vault Configuration
- **UI**: Enabled (accessible only from within the instance)
- **Listener**: TCP on port 8200 (TLS disabled for simplicity)
- **Storage Backend**: File storage
- **Initialization**: Automatic with 5 key shares, threshold of 3
- **Unsealing**: Automatically unsealed on startup
- **Secrets Engine**: KV v2 enabled at path `kv/`

## Security Considerations

### ⚠️ IMPORTANT SECURITY NOTES

1. **No Public Access**: The instance has NO public IP address. Access is only via AWS Systems Manager Session Manager.

2. **Vault Keys Storage**: 
   - Root token and unseal keys are stored in `/root/vault-init.txt`
   - This file is created with 600 permissions (root only)
   - **YOU MUST SECURE THESE KEYS IMMEDIATELY AFTER DEPLOYMENT**

3. **TLS Disabled**: 
   - TLS is disabled for simplicity in this demo setup
   - For production, enable TLS with proper certificates

4. **File Storage**:
   - Using file storage backend (not recommended for production)
   - For production, use Consul, DynamoDB, or other HA backends

## Accessing Vault

### Step 1: Connect to EC2 Instance

```bash
# Using AWS CLI
aws ssm start-session --target <instance-id> --region us-east-1

# Or use AWS Console
# Navigate to EC2 > Instances > Select instance > Connect > Session Manager
```

### Step 2: Check Vault Status

```bash
# Set Vault address (already set in /etc/profile.d/vault.sh)
export VAULT_ADDR='http://127.0.0.1:8200'

# Check Vault status
vault status
```

Expected output:
```
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Version         1.x.x
Storage Type    file
Cluster Name    vault-cluster-xxxxx
Cluster ID      xxxxx-xxxxx-xxxxx
HA Enabled      false
```

### Step 3: Retrieve Root Token

```bash
# View the initialization output (contains root token and unseal keys)
sudo cat /root/vault-init.txt
```

**Sample output:**
```
Unseal Key 1: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Unseal Key 2: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Unseal Key 3: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Unseal Key 4: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Unseal Key 5: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

Initial Root Token: hvs.xxxxxxxxxxxxxxxxxxxx
```

### Step 4: Login to Vault

```bash
# Login with root token
vault login <root-token-from-vault-init.txt>
```

## Common Vault Operations

### Working with Secrets

```bash
# Write a secret
vault kv put kv/my-secret username="admin" password="secret123"

# Read a secret
vault kv get kv/my-secret

# List secrets
vault kv list kv/

# Delete a secret
vault kv delete kv/my-secret
```

### Managing Policies

```bash
# Create a policy file
cat > my-policy.hcl <<EOF
path "kv/data/my-app/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

# Write the policy
vault policy write my-policy my-policy.hcl

# List policies
vault policy list

# Read a policy
vault policy read my-policy
```

### Creating Tokens

```bash
# Create a token with specific policy
vault token create -policy=my-policy

# Create a token with TTL
vault token create -ttl=1h

# Revoke a token
vault token revoke <token>
```

### Enable Additional Secrets Engines

```bash
# Enable AWS secrets engine
vault secrets enable aws

# Enable database secrets engine
vault secrets enable database

# Enable PKI secrets engine
vault secrets enable pki

# List enabled secrets engines
vault secrets list
```

## Vault Service Management

### Check Service Status

```bash
# Check if Vault service is running
systemctl status vault

# View Vault logs
journalctl -u vault -f

# View recent logs
journalctl -u vault -n 100
```

### Restart Vault Service

```bash
# Restart Vault
sudo systemctl restart vault

# After restart, Vault will be sealed
# You need to unseal it manually
vault operator unseal <unseal-key-1>
vault operator unseal <unseal-key-2>
vault operator unseal <unseal-key-3>
```

### Stop/Start Vault

```bash
# Stop Vault
sudo systemctl stop vault

# Start Vault
sudo systemctl start vault
```

## Unsealing Vault

If Vault becomes sealed (after restart or crash), unseal it:

```bash
# Check seal status
vault status

# Unseal (need 3 out of 5 keys)
vault operator unseal <unseal-key-1>
vault operator unseal <unseal-key-2>
vault operator unseal <unseal-key-3>

# Verify unsealed
vault status
```

## Backup and Recovery

### Backup Vault Data

```bash
# Backup the data directory
sudo tar -czf vault-backup-$(date +%Y%m%d).tar.gz /opt/vault/data

# Backup configuration
sudo tar -czf vault-config-backup-$(date +%Y%m%d).tar.gz /etc/vault.d

# Backup initialization keys (CRITICAL!)
sudo cp /root/vault-init.txt /root/vault-init-backup-$(date +%Y%m%d).txt
```

### Restore Vault Data

```bash
# Stop Vault service
sudo systemctl stop vault

# Restore data
sudo tar -xzf vault-backup-YYYYMMDD.tar.gz -C /

# Set proper permissions
sudo chown -R vault:vault /opt/vault

# Start Vault
sudo systemctl start vault

# Unseal Vault
vault operator unseal <key-1>
vault operator unseal <key-2>
vault operator unseal <key-3>
```

## Troubleshooting

### Vault Won't Start

```bash
# Check logs
journalctl -u vault -n 100

# Check configuration syntax
vault server -config=/etc/vault.d/vault.hcl -test

# Check file permissions
ls -la /opt/vault/data
ls -la /etc/vault.d
```

### Cannot Connect to Vault

```bash
# Verify Vault is running
systemctl status vault

# Check if port 8200 is listening
sudo netstat -tlnp | grep 8200

# Verify VAULT_ADDR is set
echo $VAULT_ADDR
```

### Vault is Sealed

```bash
# Check seal status
vault status

# Unseal with 3 keys
vault operator unseal <key-1>
vault operator unseal <key-2>
vault operator unseal <key-3>
```

## Production Recommendations

For production deployments, consider:

1. **High Availability**: Use Consul or cloud storage backend
2. **TLS/SSL**: Enable TLS with proper certificates
3. **Auto-Unseal**: Use AWS KMS or other auto-unseal mechanisms
4. **Monitoring**: Set up monitoring and alerting
5. **Backup Strategy**: Implement automated backup procedures
6. **Access Control**: Use proper authentication methods (LDAP, OIDC, etc.)
7. **Network Security**: Use private subnets and security groups
8. **Key Management**: Store unseal keys in a secure key management system
9. **Audit Logging**: Enable and monitor audit logs
10. **Regular Updates**: Keep Vault updated to latest stable version

## Useful Links

- [Vault Documentation](https://www.vaultproject.io/docs)
- [Vault API Documentation](https://www.vaultproject.io/api-docs)
- [Vault Tutorials](https://learn.hashicorp.com/vault)
- [Vault GitHub](https://github.com/hashicorp/vault)

## Cost Considerations

- **EC2 Instance (t2.micro)**: Free tier eligible (750 hours/month for 12 months)
- **EBS Storage**: Free tier eligible (30 GB for 12 months)
- **Data Transfer**: Free tier eligible (100 GB/month outbound)
- **After Free Tier**: ~$11.30/month

## Cleanup

To destroy all resources:

```bash
cd aws-infrastructure
terraform destroy -auto-approve
```

**Note**: This will delete the EC2 instance and all Vault data. Make sure to backup any important secrets before destroying!