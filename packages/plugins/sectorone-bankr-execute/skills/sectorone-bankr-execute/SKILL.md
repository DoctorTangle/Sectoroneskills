---
name: sectorone-bankr-execute
description: Use when the user wants to CREATE a SectorOne DLMM pool, DEPOSIT liquidity, or WITHDRAW liquidity on Base using their Bankr wallet funds — "open a pool on SectorOne", "add LP with Bankr", "withdraw my SectorOne LP", "execute liquidity on SectorOne", "submit SectorOne transaction". Builds calldata via dlmmskills CLI and submits with Bankr POST /agent/submit. NOT for chat-only bots without shell. For app deep links only use liquidity-planner. For Base MCP use dlmm-integration.
allowed-tools: Read, Glob, Grep, Bash(*), Bash(curl:*), Bash(jq:*), WebFetch, AskUserQuestion
license: MIT
metadata:
  author: Sectoroneskills
  version: "0.1.0"
  plugin: sectorone-bankr-execute
---

# SectorOne × Bankr Execute (pool / deposit / withdraw)

Execute **on-chain** SectorOne DLMM actions on **Base (8453)** using:

1. **[dlmmskills](https://github.com/DoctorTangle/dlmmskills)** CLI — exact SDK calldata (`build-create-pool`, `build-add-liquidity`, `build-remove-liquidity`)
2. **[Bankr Submit API](https://docs.bankr.chat/integrations/agent-api/submit-endpoint/)** — sign + broadcast from the **Bankr wallet**

> **Not for sandbox-only Bankr:** needs shell, `git` + `npm install` for CLI, and `BANKR_API_KEY` with write access.

> **Driver fallback:** If CLI or API unavailable → `liquidity-planner` (deep links to [app.sectorone.xyz](https://app.sectorone.xyz)).

## Preflight

```bash
export BASE_RPC_URL="https://base-rpc.publicnode.com"
export BANKR_API_KEY="bk_…"   # write access, not read-only
export SECTORONE_CLI_ROOT=/path/to/dlmmskills   # optional

bash ../../scripts/check-cli.sh
```

### Dry-run (no Bankr submit)

Validate CLI `calls[]` JSON for create / add / remove — **no** `BANKR_API_KEY`:

```bash
bash ../../scripts/dry-run-bankr-flows.sh
```

Windows: `../../scripts/dry-run-bankr-flows.ps1`. Optional `SECTORONE_DRY_RUN_LP_WALLET` for full remove calldata.

Install CLI once:

```bash
git clone https://github.com/DoctorTangle/dlmmskills.git && cd dlmmskills
cp .env.example .env && npm install
```

## Get Bankr wallet address

```bash
WALLET=$(curl -s https://api.bankr.bot/agent/user \
  -H "X-API-Key: $BANKR_API_KEY" \
  | jq -r '[.wallets[]? | select(.chainId == 8453 or .chain == "base") | .address][0]')
echo "Bankr Base wallet: $WALLET"
```

Use `$WALLET` in all `--wallet` flags below.

## Submit helper

For each object in CLI JSON `calls[]`, submit in order:

```bash
bash ../../scripts/submit-via-bankr.sh \
  "$TO" "$DATA" "${VALUE:-0x0}"
```

See [references/bankr-submit.md](../../references/bankr-submit.md).

**Always** show the CLI `summary` to the user before submitting. Stop if any submit fails.

---

## Flow A — Create pool (deploy new LB pair)

**When:** User wants a **new** token pair + bin step that does not exist yet.

### A1 — Check existing pools

```bash
cd "$SECTORONE_CLI_ROOT"   # or dlmmskills/
npm run sectorone -- list-pairs \
  --token-in 0xTokenA --token-out 0xTokenB \
  --token-in-decimals 18 --token-out-decimals 6 \
  --lb-version v2 --json
```

If pair + bin step **already exists** → use **Flow B (deposit)**, not create.

### A2 — Build create calldata

Requires explicit user confirmation (`--confirm-create`).

```bash
npm run sectorone -- build-create-pool \
  --token-x 0xTokenA \
  --token-y 0xTokenB \
  --token-x-decimals 18 \
  --token-y-decimals 6 \
  --bin-step 25 \
  --lb-version v2 \
  --price-token-y-per-token-x 3000 \
  --confirm-create \
  --json
```

Review JSON `summary` (`activeId`, `impliedSortedYPerSortedX`, `inputOrderWasSorted`) with the user.

### A3 — Submit

Usually **1 call** (`createLBPair`). Submit each entry in `calls[]`.

After success → pool exists; optional **Flow B** to deposit initial liquidity.

---

## Flow B — LP deposit (add liquidity)

**When:** User wants to **deposit** into an existing SectorOne pool using Bankr funds.

### B1 — Resolve pool (if unknown)

```bash
npm run sectorone -- list-pairs \
  --token-in 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 \
  --token-out 0x4200000000000000000000000000000000000006 \
  --token-in-decimals 6 --token-out-decimals 18 \
  --lb-version v2 --json
```

Pick `pair` + `binStep` (e.g. bin step 25).

**Alternative:** User pastes add deep link → parse `{pair}` and `{binStep}` from  
`…/liquidity/manual/:8453/add/v20/{pair}/{binStep}`

### B2 — Build add calldata

```bash
npm run sectorone -- build-add-liquidity \
  --wallet "$WALLET" \
  --token-x 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 \
  --token-y 0x4200000000000000000000000000000000000006 \
  --token-x-decimals 6 \
  --token-y-decimals 18 \
  --amount-x 100 \
  --amount-y 0 \
  --bin-step 25 \
  --lb-version v2 \
  --distribution SPOT \
  --json
```

Bankr wallet must hold enough **USDC/WETH** + **ETH for gas**.

### B3 — Submit sequence

Submit `calls[]` **in order** — typically:

1. ERC-20 `approve` (if present)
2. `addLiquidity` on router

Wait for each confirmation before the next.

---

## Flow C — LP withdraw (remove liquidity)

**When:** User wants to **withdraw** LP from specific bins using Bankr wallet.

**Troubleshooting:** [references/withdraw-troubleshooting.md](../../references/withdraw-troubleshooting.md) — #1 revert cause is **v2 vs v22 router mismatch** (e.g. DEGEN/WETH bin step 100 on v2.2 factory submitted via v2.0 router).

### C0 — Resolve LB version (mandatory — do before build)

App URL `v20` is **not** enough. Resolve factory from **pair address**:

```bash
bash ../../scripts/resolve-lb-version.sh \
  --pair 0xPairFromApp \
  --token-in 0x… --token-out 0x4200000000000000000000000000000000000006 \
  --token-in-decimals 18 --token-out-decimals 18
```

Use printed `v2` or `v22` for `list-pairs`, `read-position`, and `build-remove-liquidity`.

Verify after build: `summary.router` must be v2 (`0xd4f9…2843`) or v22 (`0x87aC…CfEC`) — **never submit the wrong router.**

### C1 — Bin IDs required

Removing requires **which bins** hold the user's LP. Sources:

- User provides bin IDs from SectorOne app / dashboard
- Prior `read-position` if bin IDs known

```bash
npm run sectorone -- read-position \
  --wallet "$WALLET" \
  --pair 0xPairAddress \
  --bin-ids 8388608,8388609 \
  --token-x 0x… --token-y 0x… \
  --token-x-decimals 6 --token-y-decimals 18 \
  --json
```

If bin IDs unknown → use **liquidity-planner** remove deep link instead.

### C2 — Build remove calldata

Require explicit user OK for full exit.

```bash
npm run sectorone -- build-remove-liquidity \
  --wallet "$WALLET" \
  --token-x 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 \
  --token-y 0x4200000000000000000000000000000000000006 \
  --token-x-decimals 6 \
  --token-y-decimals 18 \
  --bin-step 25 \
  --bin-ids 8388608,8388609 \
  --remove-all \
  --lb-version v22 \
  --json
```

Replace `v22` with the version from **C0** (often `v2`, but **v22** for newer pools — wrong version → on-chain revert).

Or `--fraction 0.5` for partial remove.

### C3 — Submit

Usually **1 call** (no approval). Submit `calls[]`.

---

## Decision tree

```text
User wants SectorOne LP action with Bankr wallet
├─ Pool does not exist?     → Flow A (create) → optional Flow B
├─ Add / deposit liquidity? → Flow B
├─ Withdraw / remove LP?      → Flow C (need bin IDs)
└─ No shell / no API key?   → liquidity-planner (deep links)
```

## Safety

- No infinite approval unless user confirms twice (`--confirm-infinite-approval`).
- `--confirm-create` mandatory for new pools.
- `--remove-all` only after explicit user confirmation.
- Validate all addresses before CLI/submit.
- Report tx hashes and final balances when possible.

## References

- [references/bankr-submit.md](../../references/bankr-submit.md)
- [references/deep-links.md](../sectorone-driver/references/deep-links.md) — app fallback
- [docs/BANKR.md](../../../../docs/BANKR.md)
- CLI playbook: [dlmmskills](https://github.com/DoctorTangle/dlmmskills) + `skills/sectorone-dlmm/plugin.md`
