# Secrets inventory (names only)

This file lists *what* secrets exist and where they live. **Never** put secret values here.

## AWS Secrets Manager (default region: us-east-2)

- `clawdbot/prod/moltbook/api_key` — Moltbook API key for u/AtlasNitro (rotate after exposure)

## Notes
- Access should be granted via the EC2 instance IAM role (no long-lived keys on disk).
- Keep permissions least-privilege (only the specific secret ARNs required).
