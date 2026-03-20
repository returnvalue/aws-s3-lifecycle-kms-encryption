# AWS provider configuration for LocalStack
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    route53        = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
    elb            = "http://localhost:4566"
    elbv2          = "http://localhost:4566"
    rds            = "http://localhost:4566"
    autoscaling    = "http://localhost:4566"
    events         = "http://localhost:4566"
    kms            = "http://localhost:4566"
  }
}

# KMS Key: The encryption foundation for our secure storage
resource "aws_kms_key" "s3_kms_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "s3-lifecycle-kms-key"
    Environment = "SysOps-Lab"
  }
}

# KMS Alias: Provides a friendly name for the KMS key
resource "aws_kms_alias" "s3_kms_alias" {
  name          = "alias/s3-secure-storage-key"
  target_key_id = aws_kms_key.s3_kms_key.key_id
}

# S3 Bucket: Secure storage for encrypted data
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "secure-lifecycle-data-bucket"

  tags = {
    Name        = "secure-lifecycle-data-bucket"
    Environment = "SysOps-Lab"
  }
}

# S3 Encryption: Enforces default encryption using our KMS CMK
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket_encryption" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# S3 Lifecycle: Automates cost optimization and data retention
resource "aws_s3_bucket_lifecycle_configuration" "secure_bucket_lifecycle" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    id     = "archive-and-cleanup-policy"
    status = "Enabled"

    # Transition to Standard-IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Expire objects after 1 year
    expiration {
      days = 365
    }
  }
}

# S3 Bucket Policy: Enforces mandatory security controls
resource "aws_s3_bucket_policy" "secure_bucket_policy" {
  bucket = aws_s3_bucket.secure_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Deny all HTTP access (Force HTTPS)
        Sid       = "AllowSSLRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.secure_bucket.arn,
          "${aws_s3_bucket.secure_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        # Enforce KMS Encryption for all uploads
        Sid       = "DenyIncorrectEncryptionHeader"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.secure_bucket.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
}

# Outputs: Key identifiers for verifying the secure lifecycle architecture
output "kms_key_arn" {
  value = aws_kms_key.s3_kms_key.arn
}

output "kms_alias_name" {
  value = aws_kms_alias.s3_kms_alias.name
}

output "secure_bucket_id" {
  value = aws_s3_bucket.secure_bucket.id
}
