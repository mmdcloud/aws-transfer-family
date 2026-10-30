# 🚀 Enterprise AWS SFTP Service with Hardened S3 Backend

[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Transfer%20Family-FF9900?logo=amazon-aws)](https://aws.amazon.com/aws-transfer-family/)
[![Security](https://img.shields.io/badge/Security-Hardened%20(CIS%20Aligned)-brightgreen)](https://aws.amazon.com/architecture/security-identity-compliance/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Production-grade, modular Terraform infrastructure for deploying an enterprise-hardened **AWS Transfer Family SFTP Server** with an **Amazon S3 backend**. Engineered following the **AWS Well-Architected Security Pillar**, featuring zero-trust perimeter controls, client-side credential hygiene, user folder sandboxing (chroot), automated encryption at rest and in transit, and CloudWatch intrusion detection.

---

## 🏗️ Production Architecture

```
                                  [ Authorized Clients / Partners ]
                                                 │
                                                 ▼ (Port 22 / SFTP)
                                     [ Route 53 (sftp.domain.com) ]
                                                 │
                                                 ▼
┌────────────────────────────────────── AWS Cloud ──────────────────────────────────────┐
│                                                                                       │
│  ┌─ Optional VPC Perimeter ────────────────────────────────────────────────────────┐  │
│  │                                                                                 │  │
│  │   Multi-AZ Subnets                                                              │  │
│  │   ┌─────────────────────────────────────────────────────────────────────────┐   │  │
│  │   │  AWS Security Group: Ingress Port 22 restricted to authorized CIDRs     │   │  │
│  │   └────────────────────────────────────┬────────────────────────────────────┘   │  │
│  │                                        │                                        │  │
│  │                                        ▼                                        │  │
│  │                    ┌──────────────────────────────────────────────┐             │  │
│  │                    │   AWS Transfer Family SFTP Server            │             │  │
│  │                    │   - Policy: TransferSecurityPolicy-2024-01   │             │  │
│  │                    │   - Protocol: SFTP (Port 22)                 │             │  │
│  │                    └──────────────────────┬───────────────────────┘             │  │
│  │                                           │                                     │  │
│  └───────────────────────────────────────────┼─────────────────────────────────────┘  │
│                                              │                                        │
│          ┌───────────────────────────────────┼────────────────────────────────┐       │
│          ▼                                   ▼                                ▼       │
│  ┌───────────────┐                 ┌────────────────────┐            ┌──────────────┐ │
│  │ IAM Transfer  │                 │ S3 Storage Bucket  │            │  CloudWatch  │ │
│  │ Least-Privilege                 │ - Server Encryption│            │  - Logs (90d)│ │
│  │ & Scope-Down  │                 │ - Enforced TLS 1.2+│            │  - Alarms    │ │
│  │ Session Policy│                 │ - Block Public Acc.│            │    (Auth-Fail│ │
│  │ (User Chroot) │                 │ - Versioning (WORM)│            │     Brute)   │ │
│  └───────────────┘                 │ - No Wildcard CORS │            └──────────────┘ │
│                                    │ - Path: /home/user │                             │
│                                    └────────────────────┘                             │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🛡️ Production & Security Controls Implemented

| Security Domain | Control Implemented | Production Benefit |
|---|---|---|
| **Credential Hygiene** | Client-Generated Keys via `var.ssh_public_key` | Eliminates private keys from `terraform.tfstate`. Private keys never leave the client machine. |
| **Data in Transit** | S3 Bucket Policy with `aws:SecureTransport = false` Deny | Guarantees all API access to backend storage is strictly encrypted over TLS 1.2+. |
| **Data at Rest** | Default S3 Server-Side Encryption (AES256 / KMS CMK) | Automatic bucket-key encryption protects all uploaded files at rest. |
| **Data Loss Prevention**| `force_destroy = false` & S3 Versioning Enabled | Prevents accidental deletion of the production bucket and preserves overwritten file versions. |
| **Access Sandboxing** | Logical Home Directory + Session Scope-Down Policy | User is chrooted to `/home/<username>/` and cannot list or access other users' directories or bucket root. |
| **Cryptography** | `TransferSecurityPolicy-2024-01` | Deprecates outdated/broken ciphers, weak key exchange (KEX) algorithms, and SHA-1. |
| **Perimeter Defense** | Optional VPC Endpoint + Security Group IP Allowlisting | Restricts SFTP access strictly to designated corporate or partner CIDR ranges. |
| **Web Hardening** | Zero Wildcard CORS (`cors = []`) | Closes unauthorized cross-origin browser access vectors to storage. |
| **Public Exposure** | S3 Public Access Block (All 4 Flags Enforced) | Guarantees the bucket can never be rendered public via ACLs or policies. |
| **Audit & Intrusion** | 90-Day CloudWatch Log Retention + Metric Alarms | Continuous audit trails with automated alerting for brute-force login attempts (`SFTPAuthenticationFailures >= 5`). |

---

## 📋 Prerequisites

- **Terraform**: `v1.5.0` or higher
- **AWS CLI**: `v2.x` configured with administrative or Transfer/S3 deployment permissions
- **OpenSSH Client**: For SFTP connection and ED25519 key generation
- **Terraform Providers**:
  - `hashicorp/aws` (~> 5.0)
  - `hashicorp/tls` (~> 4.0)
  - `hashicorp/random` (~> 3.5)

---

## 📂 Repository Structure

```
.
├── command.txt                     # Quick-reference operational commands
├── README.md                       # Production documentation & runbooks
├── screenshots/                    # Architecture and validation screenshots
└── terraform/
    ├── main.tf                     # Root composition with security hardening
    ├── outputs.tf                  # Infrastructure outputs
    ├── provider.tf                 # Provider requirements & S3 remote state template
    ├── terraform.tfvars            # Deployment environment variables
    ├── variables.tf                # Input variable declarations & validations
    └── modules/
        ├── cloudwatch/
        │   ├── cloudwatch-alarm/   # Metric alarm for auth failures & transfer errors
        │   └── cloudwatch-log-group/# Audit log group with retention & KMS support
        ├── iam/                    # Least-privilege IAM roles & policies
        ├── s3/                     # Hardened S3 bucket module (encryption, policies)
        ├── secrets-manager/        # AWS Secrets Manager module (for Custom IdP)
        └── transfer-family/        # AWS Transfer Family server, users, and policies
```

---

## ⚙️ Configuration Variables

### Input Variables (`variables.tf`)

| Variable | Description | Type | Default | Production Recommendation |
|---|---|---|---|---|
| `region` | AWS Deployment Region | `string` | `"ap-south-1"` | Set to your target deployment region. |
| `sftp_user_name` | SFTP Username | `string` | - (Required) | Unique per partner or service account. |
| `create_ssh_key` | Register an SSH public key for user | `bool` | `true` | Set `true` for SFTP SSH authentication. |
| `ssh_public_key` | Client OpenSSH Public Key | `string` | `null` | **Pass client's public key** (`id_ed25519.pub`). Avoids storing private key in state. |
| `enable_vpc_endpoint` | Deploy server inside a VPC | `bool` | `false` | Set `true` for production environments requiring IP allowlists. |
| `vpc_id` | Target VPC ID | `string` | `null` | Required if `enable_vpc_endpoint = true`. |
| `subnet_ids` | VPC Subnet IDs | `list(string)`| `[]` | Multi-AZ public or private subnets. |
| `allowed_cidr_blocks` | Permitted SFTP Client CIDRs | `list(string)`| `[]` | Whitelist client static IPs (e.g., `["203.0.113.10/32"]`). |
| `log_retention_days` | CloudWatch Log Retention | `number` | `90` | Minimum `90` (or `365` for PCI-DSS/HIPAA). |

### Outputs (`outputs.tf`)

| Output Name | Description | Sensitive |
|---|---|---|
| `sftp_server_endpoint` | Public or VPC DNS endpoint for SFTP connections | No |
| `sftp_server_id` | AWS Transfer Family Server ID | No |
| `s3_bucket_id` | Backend storage S3 bucket name | No |
| `s3_bucket_arn` | Backend storage S3 bucket ARN | No |
| `cloudwatch_log_group_arn` | CloudWatch log group capturing SFTP activity | No |
| `sftp_private_key` | Auto-generated private key for test fallback (`null` when client key supplied) | Yes |

---

## 🚀 Deployment Guide

### Step 1: Configure Remote State Backend (Production Prerequisite)

In [`terraform/provider.tf`](file:///home/shiv/mohit/aws-transfer-family/terraform/provider.tf), uncomment and configure the remote state backend to enable team locking:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-company-terraform-state-prod"
    key            = "aws-transfer-family/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

### Step 2: Prepare Client SSH Keys

#### Production Mode (Client-Generated Keys — Recommended)
Have your SFTP client generate an ED25519 or RSA 4096-bit key pair on their local machine:

```bash
# Generate key pair locally
ssh-keygen -t ed25519 -C "partner-sftp-key" -f sftp-client-key

# Copy public key string
cat sftp-client-key.pub
```

Add the public key into [`terraform/terraform.tfvars`](file:///home/shiv/mohit/aws-transfer-family/terraform/terraform.tfvars):
```hcl
region         = "ap-south-1"
sftp_user_name = "partner-prod-user"
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... partner-sftp-key"

# Optional VPC security perimeter
enable_vpc_endpoint = true
vpc_id              = "vpc-0123456789abcdef0"
subnet_ids          = ["subnet-0a1b2c3d4e", "subnet-0f1e2d3c4b"]
allowed_cidr_blocks = ["198.51.100.50/32", "203.0.113.0/24"]
```

#### Development / Quick-Test Mode (Fallback)
If `ssh_public_key` is left `null` or omitted, Terraform will generate a temporary 4096-bit RSA key pair for testing.

### Step 3: Initialize, Plan, and Deploy

```bash
cd terraform

# 1. Initialize providers and backend
terraform init

# 2. Validate configuration
terraform validate

# 3. Preview execution plan
terraform plan -out=tfplan

# 4. Apply changes
terraform apply tfplan
```

### Step 4: Retrieve Server Endpoint

```bash
terraform output -raw sftp_server_endpoint
```

---

## 🔌 Connection & Operations Runbook

### 1. Connecting via SFTP Client

Using the client's private key:
```bash
# Ensure strict private key permissions
chmod 600 sftp-client-key

# Connect to the SFTP server
sftp -i sftp-client-key <sftp-username>@<server-endpoint>
```

Example:
```bash
sftp -i sftp-client-key partner-prod-user@s-0123456789abcdef0.server.transfer.ap-south-1.amazonaws.com
```

### 2. File Transfer Operations

Because the user is chrooted directly into their sandboxed folder:

```bash
# Check current directory
sftp> pwd
Remote working directory: /

# Upload file
sftp> put financial-report.csv

# List remote files
sftp> ls -la

# Download file
sftp> get financial-report.csv

# Remove remote file
sftp> rm financial-report.csv

# Disconnect
sftp> exit
```

---

## 📊 Observability & Incident Response

### 1. Tail Live SFTP Access Logs
```bash
aws logs tail /aws/transfer/sftp-server --follow --format short
```

### 2. CloudWatch Alarm for Brute-Force Authentication Failures
The system includes a pre-configured alarm:
- **Alarm Name**: `sftp-auth-failures-high`
- **Metric**: `AWS/Transfer` -> `SFTPAuthenticationFailures`
- **Condition**: Triggers when 5 or more authentication failures occur within a 5-minute window (`period = 300`, `evaluation_periods = 1`).
- **Action**: Connect `alarm_actions` in [`terraform/main.tf`](file:///home/shiv/mohit/aws-transfer-family/terraform/main.tf#L476) to an SNS topic notifying your security operations center (SOC), PagerDuty, or Slack.

### 3. S3 Access Audit Verification
To verify in-transit TLS enforcement on the S3 bucket:
```bash
# Verify bucket policy denying non-HTTPS traffic
aws s3api get-bucket-policy --bucket $(terraform output -raw s3_bucket_id) --output json
```

---

## 💰 Cost Architecture

| AWS Component | Cost Basis | Approximate Monthly Cost | Optimization Advice |
|---|---|---|---|
| **Transfer Family Server** | ~$0.30 per active server hour | ~$216.00 / month | Share single server across multiple clients/users. |
| **Data Transfer** | $0.04 per GB transferred (in/out) | Variable (Usage-based) | Use VPC endpoints for internal VPC transfers to avoid public data rates. |
| **Amazon S3 Storage** | Standard S3 tiered pricing | ~$0.023 per GB/month | Enable S3 Lifecycle rules to transition older files to Glacier Flexible Retrieval. |
| **CloudWatch Logs** | $0.50 per GB ingested | < $5.00 / month | Retention is set to 90 days. Export older logs to S3 Glacier for long-term archiving. |

---

## 🤝 Validation & Screenshots

<img width="1561" height="727" alt="Screenshot from 2026-02-22 07-56-32" src="https://github.com/user-attachments/assets/a694e725-c7de-4041-a76f-d356a97c1ee9" />
<img width="1298" height="93" alt="Screenshot from 2026-02-22 07-57-27" src="https://github.com/user-attachments/assets/86c05fa0-e40e-4f12-8376-1c7e89de1b0d" />
<img width="405" height="45" alt="Screenshot from 2026-02-22 07-58-08" src="https://github.com/user-attachments/assets/367d581b-85a4-4870-8483-a1c7b14400ac" />
<img width="1399" height="290" alt="Screenshot from 2026-02-22 08-00-14" src="https://github.com/user-attachments/assets/34c1e1c1-0375-4b45-a215-71b17e22c3b6" />
<img width="1631" height="753" alt="Screenshot from 2026-02-23 13-48-18" src="https://github.com/user-attachments/assets/81c62345-36cc-486d-a852-da5fd8cedf81" />

---

## 🧹 Infrastructure Teardown

To destroy the infrastructure:

```bash
terraform destroy
```

> [!IMPORTANT]
> Because `force_destroy = false` is enforced for production data protection, any bucket containing objects cannot be destroyed until emptied. This prevents catastrophic data loss accidents.

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
