# 01. IAM: Identity and Access Management (Governance)

## What is IAM?
IAM is the AWS service that controls **who** can do **what** on **which** AWS resources. It answers two questions: **authentication** (who are you?) and **authorization** (what are you allowed to do?). IAM is global (not tied to a region) and free to use.

```text
Identity (user / role) ──has──► Policy (JSON permissions) ──allows or denies──► Actions on Resources
```

## Core building blocks

| Concept | What it is | Example |
| :--- | :--- | :--- |
| **User** | A person or application with long-term credentials (console password and/or access keys) | `aryan-dev` |
| **Group** | A collection of users. Attach a policy to the group and every member gets it | `Developers`, `Admins` |
| **Role** | An identity with **temporary** credentials that is *assumed* by a user, an AWS service or another account. It has no password or permanent keys | An EC2 instance role that lets the app read S3 |
| **Policy** | A JSON document that lists permissions | `AmazonS3ReadOnlyAccess` |
| **Permission** | A single allowed or denied action on a resource | `s3:GetObject` on `arn:aws:s3:::my-bucket/*` |

### Anatomy of a policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*"]
    }
  ]
}
```
- **Effect:** `Allow` or `Deny` (an explicit Deny always wins).
- **Action:** the API calls permitted (`service:Operation`).
- **Resource:** which resources it applies to (identified by ARN).
- **Condition (optional):** extra rules such as source IP, MFA required or time of day.

### Policy types
- **AWS managed:** created and maintained by AWS (e.g. `AdministratorAccess`).
- **Customer managed:** written by you and reusable.
- **Inline:** embedded directly in one user, group or role.
- **Resource-based:** attached to a resource, e.g. an S3 bucket policy.

## Permissions and evaluation
By default everything is **denied**. Access is granted only if a policy explicitly allows it and no policy explicitly denies it:
```text
Explicit Deny  >  Explicit Allow  >  Default Deny
```

## Least privilege
Give an identity **only the permissions it needs to do its job, and nothing more**. Start with no access and add what is required. Example: a backup job needs `s3:PutObject` on one bucket, not `s3:*` on `*`. This limits the damage if credentials leak.

## IAM best practices
1. **Don't use the root account** for daily work. Lock it away with MFA and create an admin IAM user or use IAM Identity Center.
2. **Enable MFA** for the root account and every human user.
3. **Apply least privilege** and review permissions regularly (IAM Access Analyzer, "last accessed" data).
4. **Use roles instead of long-term access keys** for applications and AWS services (e.g. EC2 instance profiles).
5. **Use groups** to assign permissions to users, not one-off policies per person.
6. **Never hard-code or commit access keys.** Rotate keys, and delete unused ones.
7. **Use strong password policies** and conditions (e.g. require MFA, restrict by IP).
8. **Monitor activity** with AWS CloudTrail.

## Common use cases
- Giving developers read-only or limited access to the console.
- Letting an EC2 instance or Lambda function access S3 or DynamoDB through a role (no keys on the server).
- Giving a CI/CD pipeline (e.g. GitHub Actions) a role to deploy to AWS.
- Cross-account access: a role in account A assumed by users from account B.
- Enforcing MFA for sensitive actions.

## Useful CLI commands
```bash
aws iam list-users
aws iam create-group --group-name Developers
aws iam attach-group-policy --group-name Developers --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
aws sts get-caller-identity        # who am I?
```
