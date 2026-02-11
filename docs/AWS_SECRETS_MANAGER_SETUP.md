# AWS Secrets Manager setup (recommended)

This workspace expects secrets to be stored in AWS Secrets Manager and accessed at runtime via the instance's IAM role (no long-lived access keys on disk).

## Target AWS region
- Default: `us-east-2` (override with `AWS_REGION` env var)

## Secret naming convention
Use path-like names to keep things organized:

- `clawdbot/prod/moltbook/api_key`
- `clawdbot/prod/whatsapp/...` (only if needed)
- `clawdbot/prod/other_service/...`

## 1) Create secrets
Example (API key stored as a simple string):

```bash
aws secretsmanager create-secret \
  --name clawdbot/prod/moltbook/api_key \
  --secret-string 'REPLACE_ME' \
  --region us-east-2
```

To update/rotate:

```bash
aws secretsmanager put-secret-value \
  --secret-id clawdbot/prod/moltbook/api_key \
  --secret-string 'NEW_VALUE' \
  --region us-east-2
```

## 2) Attach an IAM role to this instance (required)
This instance currently has **no IAM role** attached, so `aws sts get-caller-identity` fails.

Attach an instance profile role that allows reading *only* the secrets this agent needs.

### Minimal IAM policy (example)
Replace account id and region as needed.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOnlySpecificSecrets",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-2:YOUR_ACCOUNT_ID:secret:clawdbot/prod/moltbook/api_key-*"
      ]
    },
    {
      "Sid": "AllowKMSDecryptForSecretsManager",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "secretsmanager.us-east-2.amazonaws.com"
        }
      }
    }
  ]
}
```

Notes:
- Prefer a **customer-managed KMS key** for Secrets Manager if you want tight key policies.
- If you use the default AWS-managed key for Secrets Manager, KMS permissions may vary by setup; test `GetSecretValue`.

## 3) Runtime access pattern
Use the helper script:

```bash
bash scripts/aws-secret-get.sh clawdbot/prod/moltbook/api_key
```

It prints the secret value to stdout. Do not log it.

## 4) Local files
- Do **not** store API keys in `memory/`.
- Avoid long-lived credentials in `~/.aws/credentials`.

## Smoke test
Once the IAM role is attached:

```bash
aws sts get-caller-identity --region us-east-2
bash scripts/aws-secret-get.sh clawdbot/prod/moltbook/api_key
```
