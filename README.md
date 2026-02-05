# 🚀 AWS SFTP Server with S3 Backend

[![Terraform](https://img.shields.io/badge/Terraform-1.0%2B-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Transfer%20Family-FF9900?logo=amazon-aws)](https://aws.amazon.com/aws-transfer-family/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A production-ready Terraform configuration for deploying an AWS Transfer Family SFTP server with S3 backend storage. This solution enables secure file transfers using SFTP protocol with files stored in Amazon S3.

## 🏗️ Architecture

```
┌─────────────┐         ┌──────────────────┐         ┌─────────────┐
│   SFTP      │  SFTP   │  AWS Transfer    │   S3    │   Amazon    │
│   Client    ├────────►│  Family Server   ├────────►│   S3        │
│             │         │  (Public)        │   API   │   Bucket    │
└─────────────┘         └──────────────────┘         └─────────────┘
                               │
                               ├─ CloudWatch Logs
                               └─ IAM Role (S3 Access)
```

## ✨ Features

- **Secure SFTP Server**: Public endpoint with SSH key authentication
- **S3 Backend Storage**: All uploaded files stored in versioned S3 bucket
- **Logging**: Comprehensive CloudWatch logging with 30-day retention
- **IAM Security**: Least-privilege IAM roles for Transfer Family and CloudWatch
- **SSH Key Management**: Automated RSA 4096-bit key pair generation
- **CORS Enabled**: Pre-configured CORS for web-based access
- **Versioning**: S3 bucket versioning enabled for data protection

## 📋 Prerequisites

- **Terraform**: Version 1.0 or higher
- **AWS Account**: With appropriate permissions
- **AWS CLI**: Configured with credentials
- **Required Terraform Providers**:
  - `hashicorp/aws` (~> 5.0)
  - `hashicorp/tls` (~> 4.0)
  - `hashicorp/random` (~> 3.0)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Configure Variables

Create a `terraform.tfvars` file:

```hcl
sftp_user_name = "your-sftp-username"
aws_region     = "us-east-1"  # Optional, adjust as needed
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Deploy

```bash
terraform apply
```

### 6. Retrieve Outputs

```bash
# Get SFTP server endpoint
terraform output sftp_server_endpoint

# Get private SSH key (save this securely!)
terraform output -raw private_key > sftp_private_key.pem
chmod 600 sftp_private_key.pem

# Get S3 bucket name
terraform output s3_bucket_name
```

## 🔧 Configuration

### Input Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `sftp_user_name` | Username for SFTP access | `string` | - | Yes |
| `aws_region` | AWS region for deployment | `string` | `us-east-1` | No |

### Module Structure

```
.
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf             # Output values
├── modules/
│   ├── s3/               # S3 bucket module
│   └── iam/              # IAM role/policy module
└── README.md
```

## 📦 Resources Created

- **AWS Transfer Family Server**: SFTP server with public endpoint
- **AWS Transfer User**: SFTP user with SSH key authentication
- **S3 Bucket**: Versioned bucket with CORS configuration
- **IAM Roles**: 
  - Transfer Family role for S3 access
  - Logging role for CloudWatch
- **CloudWatch Log Group**: For server logging (30-day retention)
- **TLS Key Pair**: 4096-bit RSA key for SSH authentication

## 🔐 Security Best Practices

### Implemented

✅ **SSH Key Authentication**: RSA 4096-bit keys for secure access  
✅ **IAM Least Privilege**: Minimal permissions for Transfer Family  
✅ **S3 Versioning**: Protection against accidental deletion  
✅ **CloudWatch Logging**: Audit trail of all SFTP activities  
✅ **Service-Managed Authentication**: No credential storage required

### Recommended Enhancements

- [ ] Enable S3 bucket encryption (KMS)
- [ ] Implement VPC endpoint for private connectivity
- [ ] Add S3 lifecycle policies for cost optimization
- [ ] Enable MFA delete on S3 bucket
- [ ] Implement AWS CloudTrail for API auditing
- [ ] Add AWS Config rules for compliance
- [ ] Set up CloudWatch alarms for monitoring
- [ ] Implement IP whitelisting using security policies

## 🔌 Usage

### Connect via SFTP

```bash
sftp -i sftp_private_key.pem <sftp-username>@<server-endpoint>
```

Example:
```bash
sftp -i sftp_private_key.pem myuser@s-1234567890abcdef0.server.transfer.us-east-1.amazonaws.com
```

### Upload Files

```bash
sftp> put local-file.txt
sftp> put -r local-directory/
```

### Download Files

```bash
sftp> get remote-file.txt
sftp> get -r remote-directory/
```

### List Files

```bash
sftp> ls
sftp> ls -la
```

## 📊 Monitoring

### CloudWatch Logs

View SFTP server logs:
```bash
aws logs tail /aws/transfer/sftp-server --follow
```

### Metrics to Monitor

- Connection attempts and failures
- File upload/download operations
- Authentication failures
- Storage usage in S3 bucket

## 💰 Cost Considerations

**AWS Transfer Family Pricing** (as of 2024):
- **SFTP Endpoint**: ~$0.30/hour (~$216/month)
- **Data Transfer**: $0.04/GB uploaded or downloaded
- **S3 Storage**: Standard S3 pricing applies

**Cost Optimization Tips**:
- Use VPC endpoint for internal transfers (reduces data transfer costs)
- Implement S3 lifecycle policies to move old data to cheaper storage classes
- Delete the Transfer Family server when not in use (development environments)

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

⚠️ **Warning**: This will delete all resources including the S3 bucket and its contents if `force_destroy = true`.

## 🔄 Backup and Disaster Recovery

### S3 Versioning
- Enabled by default for data protection
- Allows recovery of deleted or overwritten files

### Recommended Backup Strategy
```hcl
# Add to your configuration
resource "aws_s3_bucket_replication_configuration" "replication" {
  # Configure cross-region replication for disaster recovery
}
```

## 🐛 Troubleshooting

### Connection Refused

**Issue**: Cannot connect to SFTP server  
**Solution**: 
- Verify server is in `ONLINE` state
- Check security group allows port 22
- Verify SSH key is correct

### Permission Denied

**Issue**: Cannot upload/download files  
**Solution**:
- Verify IAM role has correct S3 permissions
- Check home directory mapping is correct
- Review CloudWatch logs for detailed errors

### Authentication Failed

**Issue**: SSH key authentication fails  
**Solution**:
- Ensure SSH key has correct permissions (600)
- Verify public key is correctly uploaded
- Check username matches configuration

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 References

- [AWS Transfer Family Documentation](https://docs.aws.amazon.com/transfer/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/best-practices.html)

## 📧 Support

For issues and questions:
- Open an issue in the GitHub repository
- Review existing issues and discussions
- Check AWS Transfer Family documentation

---

**Note**: This configuration generates and manages SSH keys automatically. In production, consider using your own key management solution and rotating keys regularly.
