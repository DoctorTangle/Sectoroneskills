#!/usr/bin/env bash
# Submit one EVM call via Bankr POST /agent/submit
# Usage: submit-via-bankr.sh <to> <data> [value_hex]
set -euo pipefail
TO="${1:?to address required}"
DATA="${2:?calldata required}"
VALUE="${3:-0x0}"
API_KEY="${BANKR_API_KEY:?Set BANKR_API_KEY}"
curl -s -X POST "https://api.bankr.bot/agent/submit" \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg to "$TO" \
    --arg data "$DATA" \
    --arg value "$VALUE" \
    '{ transaction: { to: $to, data: $data, value: $value, chainId: 8453 }, waitForConfirmation: true }')"
