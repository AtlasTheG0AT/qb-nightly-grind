#!/usr/bin/env bash
set -euo pipefail

# Usage: aws-secret-get.sh <secret-id-or-name>
# Prints the raw SecretString to stdout.

if [[ ${1:-} == "" ]]; then
  echo "usage: $0 <secret-id-or-name>" >&2
  exit 2
fi

SECRET_ID="$1"
REGION="${AWS_REGION:-us-east-2}"

aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ID" \
  --query 'SecretString' \
  --output text \
  --region "$REGION"
