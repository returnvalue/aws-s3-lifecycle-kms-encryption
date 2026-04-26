# AWS Infrastructure Lifecycle Management Lab

This lab demonstrates foundational security and data management patterns for the **AWS SysOps Administrator Associate**: building a secure, encrypted, and cost-optimized data storage environment.

## Architecture Overview

The system implements multiple layers of security and automation:

1.  **Encryption at Rest:** A KMS Customer Managed Key (CMK) provides fine-grained encryption and auditing for all stored objects.
2.  **Mandatory Security:** An S3 Bucket Policy enforces secure transport (HTTPS) and requires KMS encryption for every upload.
3.  **Cost Management:** Automated S3 Lifecycle rules transition data through Standard-IA (30 days) and Glacier (90 days) before final expiration (365 days).
4.  **Policy Enforcement:** Server-side encryption (SSE-KMS) is configured by default for all new objects.

## Key Components

-   **KMS CMK & Alias:** The root of trust for data encryption.
-   **S3 Secure Bucket:** The durable storage layer.
-   **S3 Lifecycle Configuration:** The automated rule-set for storage class transitions.
-   **S3 Bucket Policy:** Proactive enforcement of security requirements.

## Prerequisites

-   [Terraform](https://www.terraform.io/downloads.html)
-   [LocalStack](https://localstack.cloud/)
-   [AWS CLI / awslocal](https://github.com/localstack/awscli-local)

## Deployment

1.  **Initialize and Apply:**
    ```bash
    terraform init
    terraform apply -auto-approve
    ```

## Verification & Testing

To test the security and encryption:

1.  **Upload an Object with Correct Encryption:**
    ```bash
    awslocal s3 cp README.md s3://secure-lifecycle-data-bucket/ --sse aws:kms --sse-kms-key-id alias/s3-secure-storage-key
    aws s3 cp README.md s3://secure-lifecycle-data-bucket/ --sse aws:kms --sse-kms-key-id alias/s3-secure-storage-key
    ```

2.  **Verify Encryption Status:**
    ```bash
    awslocal s3api head-object --bucket secure-lifecycle-data-bucket --key README.md
    aws s3api head-object --bucket secure-lifecycle-data-bucket --key README.md
    ```
    Confirm the `ServerSideEncryption` is `aws:kms`.

3.  **Test HTTPS Enforcement (Conceptual):**
    A standard `curl` request without TLS (if attempted against the AWS endpoint) would be blocked by the bucket policy.

4.  **Confirm Lifecycle Configuration:**
    ```bash
    awslocal s3api get-bucket-lifecycle-configuration --bucket secure-lifecycle-data-bucket
    aws s3api get-bucket-lifecycle-configuration --bucket secure-lifecycle-data-bucket
    ```

## Cleanup

To tear down the infrastructure:
```bash
terraform destroy -auto-approve
```

---

💡 **Pro Tip: Using `aws` instead of `awslocal`**

If you prefer using the standard `aws` CLI without the `awslocal` wrapper or repeating the `--endpoint-url` flag, you can configure a dedicated profile in your AWS config files.

### 1. Configure your Profile
Add the following to your `~/.aws/config` file:
```ini
[profile localstack]
region = us-east-1
output = json
# This line redirects all commands for this profile to LocalStack
endpoint_url = http://localhost:4566
```

Add matching dummy credentials to your `~/.aws/credentials` file:
```ini
[localstack]
aws_access_key_id = test
aws_secret_access_key = test
```

### 2. Use it in your Terminal
You can now run commands in two ways:

**Option A: Pass the profile flag**
```bash
aws iam create-user --user-name DevUser --profile localstack
```

**Option B: Set an environment variable (Recommended)**
Set your profile once in your session, and all subsequent `aws` commands will automatically target LocalStack:
```bash
export AWS_PROFILE=localstack
aws iam create-user --user-name DevUser
```

### Why this works
- **Precedence**: The AWS CLI (v2) supports a global `endpoint_url` setting within a profile. When this is set, the CLI automatically redirects all API calls for that profile to your local container instead of the real AWS cloud.
- **Convenience**: This allows you to use the standard documentation commands exactly as written, which is helpful if you are copy-pasting examples from AWS labs or tutorials.
