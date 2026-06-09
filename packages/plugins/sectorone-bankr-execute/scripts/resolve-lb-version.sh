#!/usr/bin/env bash
# Resolve LB factory version (v2 or v22) for a SectorOne pair on Base.
# Usage:
#   bash scripts/resolve-lb-version.sh \
#     --pair 0xPairAddress \
#     --token-in 0x… --token-out 0x… \
#     --token-in-decimals 18 --token-out-decimals 18
#
# Prints: v2 or v22 (stdout). Exit 1 if pair not found on either factory.
set -euo pipefail

PAIR=""
TOKEN_IN=""
TOKEN_OUT=""
IN_DEC=""
OUT_DEC=""

while [ $# -gt 0 ]; do
  case "$1" in
    --pair) PAIR="$2"; shift 2 ;;
    --token-in) TOKEN_IN="$2"; shift 2 ;;
    --token-out) TOKEN_OUT="$2"; shift 2 ;;
    --token-in-decimals) IN_DEC="$2"; shift 2 ;;
    --token-out-decimals) OUT_DEC="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$PAIR" ] || [ -z "$TOKEN_IN" ] || [ -z "$TOKEN_OUT" ] || [ -z "$IN_DEC" ] || [ -z "$OUT_DEC" ]; then
  echo "Usage: resolve-lb-version.sh --pair 0x… --token-in 0x… --token-out 0x… --token-in-decimals N --token-out-decimals N" >&2
  exit 2
fi

ROOT="${SECTORONE_CLI_ROOT:-}"
if [ -z "$ROOT" ]; then
  if [ -f "./package.json" ] && grep -q '"sectorone"' package.json 2>/dev/null; then
    ROOT="$(pwd)"
  elif [ -d "dlmmskills" ] && [ -f "dlmmskills/package.json" ]; then
    ROOT="$(cd dlmmskills && pwd)"
  fi
fi
if [ -z "$ROOT" ] || [ ! -f "$ROOT/package.json" ]; then
  echo "MISSING_CLI: set SECTORONE_CLI_ROOT to dlmmskills clone" >&2
  exit 1
fi

export BASE_RPC_URL="${BASE_RPC_URL:-https://base-rpc.publicnode.com}"
PAIR_LC="$(echo "$PAIR" | tr '[:upper:]' '[:lower:]')"

run_list() {
  local version="$1"
  (cd "$ROOT" && npx tsx src/cli/sectorone.ts list-pairs \
    --token-in "$TOKEN_IN" --token-out "$TOKEN_OUT" \
    --token-in-decimals "$IN_DEC" --token-out-decimals "$OUT_DEC" \
    --lb-version "$version" --json 2>/dev/null)
}

if ! command -v jq >/dev/null 2>&1; then
  echo "jq required" >&2
  exit 1
fi

for V in v2 v22; do
  JSON="$(run_list "$V")" || continue
  if echo "$JSON" | jq -e --arg p "$PAIR_LC" \
    '.pairs[] | select(.pair | ascii_downcase == $p)' >/dev/null 2>&1; then
    BIN="$(echo "$JSON" | jq -r --arg p "$PAIR_LC" \
      '.pairs[] | select(.pair | ascii_downcase == $p) | .binStep')"
    echo "$V"
    echo "binStep=$BIN" >&2
    exit 0
  fi
done

echo "PAIR_NOT_FOUND: $PAIR not listed for this token pair on v2 or v22" >&2
exit 1
