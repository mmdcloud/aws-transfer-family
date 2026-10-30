terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # -----------------------------------------------------------------------------------------
  # Production Remote State Backend with S3 and DynamoDB State Locking
  # Uncomment and configure with your organization's backend bucket and DynamoDB table.
  # -----------------------------------------------------------------------------------------
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "aws-transfer-family/production/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "production"
      Project     = "aws-transfer-family"
      ManagedBy   = "Terraform"
    }
  }
}