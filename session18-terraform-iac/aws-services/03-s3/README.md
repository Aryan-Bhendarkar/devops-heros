# 03. S3: Simple Storage Service (Storage)

## What is S3?
S3 is AWS **object storage**: you store any amount of files over HTTP and retrieve them from anywhere. It is designed for very high durability (11 nines) and availability, scales automatically, and you pay for what you store and transfer. It is not a disk you mount like EBS. You upload and download whole objects through an API.

## Buckets and objects
- **Bucket:** a container for objects. Its name must be **globally unique** across all AWS accounts, lowercase, 3-63 characters. A bucket lives in one **region**.
- **Object:** the file plus its metadata. Each object has a **key** (its full path/name, e.g. `images/logo.png`), a value (the data, up to 5 TB per object), metadata and an optional version ID. There are no real folders. `images/` is just part of the key.
```text
s3://my-bucket/images/logo.png     bucket = my-bucket     key = images/logo.png
```

## Storage classes
| Class | For | Notes |
| :--- | :--- | :--- |
| **S3 Standard** | Frequently accessed data | Default, millisecond access |
| **Intelligent-Tiering** | Unknown or changing access patterns | Moves objects between tiers automatically |
| **Standard-IA** (Infrequent Access) | Rarely accessed but needed quickly | Cheaper storage, retrieval fee |
| **One Zone-IA** | Re-creatable infrequent data | Stored in one AZ only, cheaper |
| **Glacier Instant / Flexible Retrieval** | Archives | Very cheap, retrieval in ms to hours |
| **Glacier Deep Archive** | Long-term archive (years) | Cheapest, retrieval takes hours |

## Versioning
When enabled, S3 keeps **every version** of an object. Overwriting creates a new version and deleting adds a *delete marker*, so you can recover accidental deletes and overwrites. Once enabled it can only be suspended, not removed. Old versions cost storage, so pair it with lifecycle rules.

## Lifecycle policies
Rules that automatically **transition** objects to cheaper classes or **expire** (delete) them over time. Example: move to Standard-IA after 30 days, to Glacier after 90 days, delete after 365 days. They can also clean up old versions and incomplete uploads.

## Encryption
- **At rest:** S3 now encrypts all new objects by default (**SSE-S3**, keys managed by S3). Other options: **SSE-KMS** (AWS KMS keys with audit trail and access control) and **SSE-C** (customer-provided keys), or client-side encryption.
- **In transit:** use HTTPS (TLS); a bucket policy can deny non-HTTPS requests.

## Access control and bucket policies
- **Block Public Access** is on by default and should stay on unless you really host public content.
- **Bucket policy:** a JSON resource-based policy on the bucket, e.g. allow another account, or require encryption/HTTPS.
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"AWS": "arn:aws:iam::123456789012:role/app-role"},
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::my-bucket/*"
  }]
}
```
- Other controls: IAM policies, ACLs (legacy), and presigned URLs for temporary access.

## Common use cases
- Static website hosting and storing images/videos/user uploads.
- Backups and disaster-recovery copies.
- Data lakes and log storage (CloudTrail, application logs).
- Storing build artifacts and **Terraform remote state**.
- Archiving old data cheaply with Glacier.

## CLI examples
```bash
aws s3 mb s3://my-unique-bucket-name
aws s3 cp file.txt s3://my-unique-bucket-name/
aws s3 ls s3://my-unique-bucket-name
aws s3api put-bucket-versioning --bucket my-unique-bucket-name --versioning-configuration Status=Enabled
aws s3 rb s3://my-unique-bucket-name --force
```
