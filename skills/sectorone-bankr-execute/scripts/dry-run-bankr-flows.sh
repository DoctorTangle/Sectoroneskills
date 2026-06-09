#!/usr/bin/env bash
# End-to-end dry-run: validate SectorOne CLI JSON for Bankr execute flows.
# Does NOT call Bankr /agent/submit. BANKR_API_KEY is optional.
set -euo pipefail

PASS=0
FAIL=0
SKIP=0

pass() { echo "PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $*" >&2; FAIL=$((FAIL + 1)); }
skip() { echo "SKIP: $*"; SKIP=$((SKIP + 1)); }

ROOT="${SECTORONE_CLI_ROOT:-}"
if [ -z "$ROOT" ]; then
  if [ -f "./package.json" ] && grep -q '"sectorone"' package.json 2>/dev/null; then
    ROOT="$(pwd)"
  elif [ -d "dlmmskills" ] && [ -f "dlmmskills/package.json" ]; then
    ROOT="$(cd dlmmskills && pwd)"
  fi
fi

if [ -z "$ROOT" ] || [ ! -f "$ROOT/package.json" ]; then
  echo "FAIL: Clone https://github.com/DoctorTangle/dlmmskills and run npm install." >&2
  echo "Set SECTORONE_CLI_ROOT to the repo path if needed." >&2
  exit 1
fi

if [ ! -d "$ROOT/_sectorone-ref/packages/v2" ]; then
  echo "FAIL: Run npm install in $ROOT (missing SDK)." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "FAIL: jq is required for JSON validation." >&2
  exit 1
fi

export BASE_RPC_URL="${BASE_RPC_URL:-https://base-rpc.publicnode.com}"

USDC="0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
WETH="0x4200000000000000000000000000000000000006"
DAI="0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb"
DRY_WALLET="${SECTORONE_DRY_RUN_WALLET:-0x0000000000000000000000000000000000000001}"
LP_WALLET="${SECTORONE_DRY_RUN_LP_WALLET:-}"
BIN_STEP="${SECTORONE_DRY_RUN_BIN_STEP:-25}"

run_sectorone() {
  (cd "$ROOT" && npx tsx src/cli/sectorone.ts "$@")
}

validate_payload() {
  local label="$1"
  local json="$2"
  local action="$3"

  if ! echo "$json" | jq -e \
    --arg action "$action" \
    '.chain == "base"
     and .summary.action == $action
     and (.calls | length) > 0
     and all(.calls[]; (.to | type) == "string" and (.data | startswith("0x")) and (.value | type) == "string")' \
    >/dev/null 2>&1; then
    fail "$label: payload failed jq validation"
    echo "$json" | head -30 >&2
    return 1
  fi

  local n
  n="$(echo "$json" | jq '.calls | length')"
  pass "$label ($n call(s), action=$action)"
}

expect_error() {
  local label="$1"
  local pattern="$2"
  shift 2
  local out
  if out="$(run_sectorone "$@" 2>&1)"; then
    fail "$label: expected error matching /$pattern/"
    return 1
  fi
  if echo "$out" | grep -qE "$pattern"; then
    pass "$label (expected error: $pattern)"
    return 0
  fi
  fail "$label: got error but not /$pattern/"
  echo "$out" | tail -5 >&2
  return 1
}

echo "=== SectorOne Bankr execute dry-run ==="
echo "CLI root: $ROOT"
echo "RPC: $BASE_RPC_URL"
echo "Dry wallet: $DRY_WALLET"
if [ -n "$LP_WALLET" ]; then
  echo "LP wallet (full remove test): $LP_WALLET"
else
  echo "LP wallet: (not set — remove calldata uses partial validation)"
fi
echo ""

# --- list-pairs ---
echo "--- list-pairs ---"
LIST_JSON="$(run_sectorone list-pairs \
  --token-in "$USDC" --token-out "$WETH" \
  --token-in-decimals 6 --token-out-decimals 18 \
  --lb-version v2 --json)" || true

if echo "$LIST_JSON" | jq -e '.chainId == 8453 and (.pairs | length) > 0' >/dev/null 2>&1; then
  pass "list-pairs (${#LIST_JSON} bytes, $(echo "$LIST_JSON" | jq '.pairs | length') pairs)"
else
  fail "list-pairs: invalid JSON"
fi

# --- Flow A: create pool (USDC/DAI — pair unlikely to exist) ---
echo "--- Flow A: build-create-pool ---"
CREATE_JSON="$(run_sectorone build-create-pool \
  --token-x "$USDC" --token-y "$DAI" \
  --token-x-decimals 6 --token-y-decimals 18 \
  --bin-step "$BIN_STEP" --lb-version v2 \
  --price-token-y-per-token-x 1 \
  --confirm-create --json 2>&1)" || CREATE_EXIT=$?

CREATE_EXIT="${CREATE_EXIT:-0}"
if [ "$CREATE_EXIT" -eq 0 ]; then
  validate_payload "create pool" "$CREATE_JSON" "createLBPair"
elif echo "$CREATE_JSON" | grep -q 'PAIR_ALREADY_EXISTS'; then
  pass "create pool preflight (PAIR_ALREADY_EXISTS — use Flow B instead)"
else
  fail "create pool: unexpected error"
  echo "$CREATE_JSON" | tail -8 >&2
fi
unset CREATE_EXIT

# --- Flow B: add liquidity ---
echo "--- Flow B: build-add-liquidity ---"
ADD_JSON="$(run_sectorone build-add-liquidity \
  --wallet "$DRY_WALLET" \
  --token-x "$USDC" --token-y "$WETH" \
  --token-x-decimals 6 --token-y-decimals 18 \
  --amount-x 1 --amount-y 0.0001 \
  --bin-step "$BIN_STEP" --lb-version v2 --json)" || true

if validate_payload "add liquidity" "$ADD_JSON" "addLiquidity"; then
  ACTIVE_ID="$(echo "$ADD_JSON" | jq -r '.summary.activeId // empty')"
  PAIR_ADDR="$(echo "$ADD_JSON" | jq -r '.summary.pair // empty')"
else
  ACTIVE_ID=""
  PAIR_ADDR=""
fi

# --- Flow C: remove liquidity ---
echo "--- Flow C: build-remove-liquidity ---"
expect_error "remove mode guard" "REMOVE_MODE_REQUIRED" \
  build-remove-liquidity \
  --wallet "$DRY_WALLET" \
  --token-x "$USDC" --token-y "$WETH" \
  --token-x-decimals 6 --token-y-decimals 18 \
  --bin-step "$BIN_STEP" --bin-ids "${ACTIVE_ID:-8380586}" || true

if [ -n "$LP_WALLET" ] && [ -n "$PAIR_ADDR" ] && [ -n "$ACTIVE_ID" ]; then
  REMOVE_JSON="$(run_sectorone build-remove-liquidity \
    --wallet "$LP_WALLET" \
    --token-x "$USDC" --token-y "$WETH" \
    --token-x-decimals 6 --token-y-decimals 18 \
    --bin-step "$BIN_STEP" \
    --bin-ids "$ACTIVE_ID" \
    --remove-all --lb-version v2 --json 2>&1)" || REMOVE_EXIT=$?

  REMOVE_EXIT="${REMOVE_EXIT:-0}"
  if [ "$REMOVE_EXIT" -eq 0 ]; then
    validate_payload "remove liquidity (LP wallet)" "$REMOVE_JSON" "removeLiquidity"
  else
    fail "remove liquidity with SECTORONE_DRY_RUN_LP_WALLET"
    echo "$REMOVE_JSON" | tail -8 >&2
  fi
elif [ -n "$ACTIVE_ID" ]; then
  expect_error "remove preflight (no LP)" "NO_LP_IN_BIN" \
    build-remove-liquidity \
    --wallet "$DRY_WALLET" \
    --token-x "$USDC" --token-y "$WETH" \
    --token-x-decimals 6 --token-y-decimals 18 \
    --bin-step "$BIN_STEP" \
    --bin-ids "$ACTIVE_ID" \
    --remove-all --lb-version v2 --json || true
  skip "remove calldata JSON — set SECTORONE_DRY_RUN_LP_WALLET for full validation"
else
  skip "remove flow — add liquidity step failed"
fi

echo ""
echo "=== Summary: $PASS passed, $FAIL failed, $SKIP skipped ==="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
