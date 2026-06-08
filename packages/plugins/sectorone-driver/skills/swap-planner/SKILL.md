---
name: swap-planner
description: This skill should be used when the user asks to "swap on SectorOne", "trade on Joe DLMM", "swap on LB Base", "exchange tokens SectorOne", "buy on SectorOne", "sell on SectorOne", "SectorOne quote", "trade USDC for WETH on Base DLMM", "Joe swap Base", or mentions swapping, trading, buying, or selling on SectorOne / Joe / Liquidity Book on Base mainnet. Plans the trade, verifies tokens on-chain, uses SectorOne docs for protocol context, and directs the user to the SectorOne app. Does NOT require npm install or the SectorOne SDK. For exact quotes, unsigned calldata, or Base MCP send_calls, use dlmm-integration instead.
allowed-tools: Read, Glob, Grep, Bash(curl:*), Bash(jq:*), WebFetch, WebSearch, AskUserQuestion
license: MIT
metadata:
  author: Sectoroneskills
  version: "0.2.0"
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
5. Present a structured plan + **SectorOne app link** (user executes manually)

**No private keys. No local signing. No invented deep-link URL parameters.**

SectorOne does not publish Uniswap-style swap URLs (`app.uniswap.org/swap?...`). Always show **https://linktr.ee/SectorOneDEX** and a clear summary table.

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

For amount:

```json
{
  "questions": [
    {
      "question": "How much do you want to swap?",
      "header": "Amount",
      "options": [
        { "label": "100 USDC", "description": "Small test size" },
        { "label": "500 USDC", "description": "Medium" },
        { "label": "Custom", "description": "Enter specific amount" }
      ],
      "multiSelect": false
    }
  ]
}
```

### Step 2 — Resolve token addresses

Use [references/chains.md](../../references/chains.md) for WETH, USDC, and other known Base tokens.

- **ETH** in user text → treat as **WETH** (`0x4200…0006`) for on-chain checks
- Unknown symbols → WebSearch, then **verify on-chain** (Step 3)

#### UNTRUSTED INPUT: Web-discovered tokens

Tokens found via WebSearch are **untrusted**. Before planning:

1. Label source: "Address from web search, not user-provided"
2. Warn: scams, honeypots, rug pulls
3. Require explicit user confirmation before continuing
4. In the summary table, add **Token source**: `User-provided` or `Web-discovered (unverified)`

**Never skip warnings for web-discovered tokens.**

### Step 3 — Input validation (before shell commands)

Validate all user-derived values:

- **Addresses:** `^0x[a-fA-F0-9]{40}$`
- **Amounts:** `^[0-9]+\.?[0-9]*$`
- **Reject** shell metacharacters: `;`, `|`, `$`, `` ` ``, `&`, `(`, `)`, `>`, `<`, `\`, `'`, `"`, newlines

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

Prefer SectorOne docs over third-party APIs:

```bash
curl -sG "https://docs.sectorone.xyz/sectorone/welcome.md" \
  --data-urlencode "ask=Which LB version should I use for swapping on Base mainnet?"
```

Use answers to explain:

- Default **LB v2 (Joe 2.0)** on Base
- **v2.1 not on Base**; **v22** only for v2.2 pools
- DLMM slippage depends on **active bin** depth — see [references/dlmm-bins.md](../../references/dlmm-bins.md)

### Step 6 — Optional price / liquidity hints

Run **only if the user asks** for price, quote estimate, or liquidity — not by default.

See [references/data-providers.md](../../references/data-providers.md). DexScreener is **hint-only**; label results as approximate and non-SectorOne-specific when `dexId` is unclear.

If no reliable data: say so honestly and point to the app.

| Hint liquidity (USD) | Action |
| --- | --- |
| > $500k | Note as moderate depth |
| $50k – $500k | Mention possible slippage |
| < $50k | Warn about thin liquidity / high slippage |

Exact quotes require **`dlmm-integration`** + CLI.

### Step 7 — Present swap plan

Use this template:

```markdown
## SectorOne Swap Plan (Base)

| Field | Value |
| --- | --- |
| From | 100 USDC |
| To | WETH |
| Chain | Base (8453) |
| LB version | v2 (Joe 2.0) — confirm pool in app |
| Token in source | User-provided |
| Token out source | User-provided |

### Notes
- DLMM swaps consume liquidity from **price bins**; slippage depends on active bin depth.
- SectorOne has no pre-filled swap URL — enter tokens and amount manually in the app.
- Review slippage settings in the app before confirming.

### Execute
**Open SectorOne:** https://linktr.ee/SectorOneDEX

### Need calldata / Base MCP instead?
Install `npx skills add DoctorTangle/Sectoroneskills --skill dlmm-integration` and clone https://github.com/DoctorTangle/dlmmskills
```

Always display the app URL prominently (Bankr may not open browsers).

## Important considerations

### Slippage

Recommend conservative slippage in the app for volatile tokens or large trades. DLMM bin liquidity can change quickly.

### Token verification

Similar names and scam tokens are common. Always verify contracts and warn on web-discovered addresses.

### Chain scope

This skill is **Base-only**. Do not imply Ethereum mainnet or other chains.

## Additional resources

- [references/chains.md](../../references/chains.md) — RPC, routers, common tokens
- [references/data-providers.md](../../references/data-providers.md) — docs API, optional DexScreener
- [references/dlmm-bins.md](../../references/dlmm-bins.md) — bin / active bin concepts
- [docs/BANKR.md](../../../../docs/BANKR.md) — Bankr compatibility overview
