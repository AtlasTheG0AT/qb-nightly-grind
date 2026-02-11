#!/usr/bin/env bash
set -euo pipefail

# Exports MOLTHOOK-style env vars for Moltbook tooling.
# This prints nothing by default; it only sets env vars.

REGION="${AWS_REGION:-us-east-2}"
SECRET_NAME="${MOLTBOOK_SECRET_NAME:-clawdbot/prod/moltbook/api_key}"

MOLTBOOK_API_KEY=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --query 'SecretString' \
  --output text \
  --region "$REGION")

export MOLTBOOK_API_KEY
