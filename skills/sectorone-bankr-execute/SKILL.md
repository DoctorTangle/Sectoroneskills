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

On-chain SectorOne DLMM on **Base (8453)** via **dlmmskills CLI** + **[Bankr Submit](https://docs.bankr.chat/integrations/agent-api/submit-endpoint/)**.

## Preflight

```bash
export BASE_RPC_URL="https://base-rpc.publicnode.com"
export BANKR_API_KEY="bk_…"
bash scripts/check-cli.sh
```

CLI: `git clone https://github.com/DoctorTangle/dlmmskills.git && cd dlmmskills && npm install`

```bash
WALLET=$(curl -s https://api.bankr.bot/agent/user -H "X-API-Key: $BANKR_API_KEY" \
  | jq -r '[.wallets[]? | select(.chainId == 8453 or .chain == "base") | .address][0]')
```

Submit each CLI `calls[]` item in order: `bash scripts/submit-via-bankr.sh "$TO" "$DATA" "$VALUE"`

Details: [references/bankr-submit.md](references/bankr-submit.md)

---

## Flow A — Create pool

1. `list-pairs` — if pool exists → Flow B instead  
2. `build-create-pool … --confirm-create --json` — review `summary` with user  
3. Submit `calls[]` (usually 1× `createLBPair`)

```bash
npm run sectorone -- build-create-pool \
  --token-x 0x… --token-y 0x… --token-x-decimals 18 --token-y-decimals 6 \
  --bin-step 25 --lb-version v2 --price-token-y-per-token-x 3000 \
  --confirm-create --json
```

## Flow B — LP deposit

1. `list-pairs` or parse add deep link for `pair` + `binStep`  
2. `build-add-liquidity --wallet "$WALLET" … --json`  
3. Submit `calls[]` in order (approve → addLiquidity)

```bash
npm run sectorone -- build-add-liquidity \
  --wallet "$WALLET" \
  --token-x 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 \
  --token-y 0x4200000000000000000000000000000000000006 \
  --token-x-decimals 6 --token-y-decimals 18 \
  --amount-x 100 --amount-y 0 --bin-step 25 --lb-version v2 --json
```

## Flow C — LP withdraw

1. Get **bin IDs** (user or `read-position`)  
2. `build-remove-liquidity --wallet "$WALLET" --bin-ids … --remove-all --json`  
3. Submit `calls[]`

If bin IDs unknown → `liquidity-planner` remove deep link.

---

## Escalation

| Need | Skill |
| --- | --- |
| App link only | `liquidity-planner` |
| Base MCP | `dlmm-integration` |

Full playbook: `packages/plugins/sectorone-bankr-execute/skills/sectorone-bankr-execute/SKILL.md` in repo.

See [docs/BANKR.md](../../docs/BANKR.md).
