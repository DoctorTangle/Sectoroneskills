---
name: swap-planner
description: This skill should be used when the user asks to "swap on SectorOne", "trade on Joe DLMM", "swap on LB Base", "exchange tokens SectorOne", "buy on SectorOne", "sell on SectorOne", "SectorOne quote", "trade USDC for WETH on Base DLMM", "Joe swap Base", or mentions swapping, trading, buying, or selling on SectorOne / Joe / Liquidity Book on Base mainnet. Plans the trade, verifies tokens on-chain, generates app.sectorone.xyz swap deep links, and uses SectorOne docs for protocol context. Does NOT require npm install or the SectorOne SDK. For exact quotes, unsigned calldata, or Base MCP send_calls, use dlmm-integration instead.
allowed-tools: Read, Glob, Grep, Bash(curl:*), Bash(jq:*), WebFetch, WebSearch, AskUserQuestion
license: MIT
metadata:
  author: Sectoroneskills
  version: "0.2.1"
  plugin: sectorone-driver
---

# SectorOne Swap Planner (Bankr-safe)

Plan SectorOne DLMM swaps on **Base mainnet only** (`chainId` `8453`). For **Bankr bots and chat-only agents** that cannot run `npm install` or clone the vendored SectorOne SDK.

> **Runtime compatibility:** Uses `AskUserQuestion` when available. If not supported (some Bankr runtimes), collect the same fields via natural language.

> **Escalate to `dlmm-integration`** when the user needs unsigned calldata, Base MCP `send_calls`, or SDK-exact quotes.

## Overview

1. Gather swap intent (tokens, amount — chain is always Base)
2. Resolve and verify token contracts on-chain
3. Add protocol context via SectorOne docs API
4. Optionally fetch rough market hints (only if user asks price/liquidity)
5. Present plan + **swap deep link** ([deep-links.md](references/deep-links.md))

SectorOne does not pre-fill **amount** in swap URLs — user enters it in the app.

## Workflow

### Step 1 — Gather swap intent

| Parameter | Required | Example |
| --- | --- | --- |
| Token in | Yes | USDC, WETH, `0x8335…` |
| Token out | Yes | WETH, address |
| Amount | Yes | `100` USDC, `0.5` ETH |
| Chain | Fixed | Base only |

**Reject non-Base chains** with a short note: SectorOne DLMM skills cover Base mainnet only.

**If parameters are missing, use AskUserQuestion** (or ask in chat):

```json
{
  "questions": [
    {
      "question": "What do you want to swap?",
      "header": "Swap",
      "options": [
        { "label": "USDC → WETH", "description": "Common Base pair" },
        { "label": "WETH → USDC", "description": "Sell ETH for stablecoin" },
        { "label": "Custom pair", "description": "Specify tokens and amount" }
      ],
      "multiSelect": false
    }
  ]
}
```

### Step 2 — Resolve token addresses

Use [references/chains.md](references/chains.md) for WETH, USDC, and other known Base tokens.

- **ETH** in user text → treat as **WETH** (`0x4200…0006`) for on-chain checks
- Unknown symbols → WebSearch, then verify on-chain

#### UNTRUSTED INPUT: Web-discovered tokens

Tokens found via WebSearch are **untrusted**. Label source, warn about scams, require user confirmation, and show **Token source** in the summary table.

### Step 3 — Input validation (before shell commands)

- **Addresses:** `^0x[a-fA-F0-9]{40}$`
- **Amounts:** `^[0-9]+\.?[0-9]*$`
- **Reject** shell metacharacters

### Step 4 — Verify contracts (curl + RPC)

```bash
RPC="https://base-rpc.publicnode.com"
ADDR="0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
curl -s -X POST "$RPC" -H "Content-Type: application/json" \
  -d "$(jq -n --arg a "$ADDR" '{"jsonrpc":"2.0","method":"eth_getCode","params":[$a,"latest"],"id":1}')" \
  | jq -r '.result'
```

Result must not be `0x`. Repeat for both tokens.

### Step 5 — Protocol context (docs API)

```bash
curl -sG "https://docs.sectorone.xyz/sectorone/welcome.md" \
  --data-urlencode "ask=Which LB version should I use for swapping on Base mainnet?"
```

Explain default **LB v2**, v2.1 not on Base, DLMM bin slippage — see [references/dlmm-bins.md](references/dlmm-bins.md).

### Step 6 — Optional price / liquidity hints

Run **only if the user asks**. See [references/data-providers.md](references/data-providers.md). DexScreener is hint-only.

| Hint liquidity (USD) | Action |
| --- | --- |
| > $500k | Moderate depth |
| $50k – $500k | Possible slippage |
| < $50k | Warn thin liquidity |

Exact quotes → **`dlmm-integration`** + CLI.

### Step 7 — Swap deep link

```text
https://app.sectorone.xyz/swap?inputCurrency={tokenIn}&outputCurrency={tokenOut}
```

Example USDC → WETH: see [references/deep-links.md](references/deep-links.md).

### Step 8 — Present swap plan

```markdown
## SectorOne Swap Plan (Base)

| Field | Value |
| --- | --- |
| From | 100 USDC |
| To | WETH |
| Chain | Base (8453) |
| LB version | v2 (Joe 2.0) — confirm pool in app |

### Notes
- DLMM swaps use **price bins**; slippage depends on active bin depth.
- Enter tokens and amount manually in the app (no pre-filled swap URL).

### Execute
**Open SectorOne:** https://app.sectorone.xyz/swap?inputCurrency=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913&outputCurrency=0x4200000000000000000000000000000000000006

### Need calldata?
`npx skills add DoctorTangle/Sectoroneskills --skill dlmm-integration` + https://github.com/DoctorTangle/dlmmskills
```

## Additional resources

- [references/chains.md](references/chains.md)
- [references/data-providers.md](references/data-providers.md)
- [references/dlmm-bins.md](references/dlmm-bins.md)
- [references/deep-links.md](references/deep-links.md)
- [docs/BANKR.md](../../docs/BANKR.md)
