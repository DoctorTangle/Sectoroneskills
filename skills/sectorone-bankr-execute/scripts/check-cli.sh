#!/usr/bin/env bash
set -euo pipefail
ROOT="${SECTORONE_CLI_ROOT:-}"
if [ -z "$ROOT" ]; then
  if [ -f "./package.json" ] && grep -q '"sectorone"' package.json 2>/dev/null; then
    ROOT="$(pwd)"
  elif [ -d "dlmmskills" ] && [ -f "dlmmskills/package.json" ]; then
    ROOT="$(cd dlmmskills && pwd)"
  fi
fi
if [ -z "$ROOT" ] || [ ! -f "$ROOT/package.json" ]; then
  echo "MISSING_CLI: Clone https://github.com/DoctorTangle/dlmmskills and npm install." >&2
  exit 1
fi
if [ ! -d "$ROOT/_sectorone-ref/packages/v2" ]; then
  echo "MISSING_SDK: npm install in $ROOT" >&2
  exit 1
fi
if [ -z "${BASE_RPC_URL:-}" ]; then
  echo "WARN: BASE_RPC_URL not set" >&2
fi
if [ -z "${BANKR_API_KEY:-}" ]; then
  echo "MISSING_BANKR_API_KEY" >&2
  exit 1
fi
echo "OK: CLI=$ROOT"
exit 0
