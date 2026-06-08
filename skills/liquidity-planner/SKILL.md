---
name: liquidity-planner
description: This skill should be used when the user asks to "provide liquidity SectorOne", "add liquidity DLMM", "LP on Joe Base", "liquidity on SectorOne", "DLMM bins", "bin step", "concentrated liquidity SectorOne", "remove liquidity SectorOne", "withdraw LP SectorOne", or mentions liquidity pools, LP positions, bins, or being a liquidity provider on SectorOne / Joe / Liquidity Book on Base mainnet. Plans DLMM liquidity context and generates app.sectorone.xyz add-LP deep links. Does NOT require npm install. For unsigned add/remove calldata or Base MCP send_calls, use dlmm-integration instead.
allowed-tools: Read, Glob, Grep, Bash(curl:*), Bash(jq:*), WebFetch, WebSearch, AskUserQuestion
license: MIT
metadata:
  author: Sectoroneskills
  version: "0.2.1"
  plugin: sectorone-driver
---

# SectorOne Liquidity Planner (Bankr-safe)

Plan DLMM **liquidity positions** on **Base mainnet only**. For Bankr bots that cannot run the SectorOne SDK or CLI.

> **Runtime compatibility:** Uses `AskUserQuestion` when available; otherwise ask in natural language.

> **Escalate to `dlmm-integration`** for `build-add-liquidity`, `build-remove-liquidity`, `read-position`, or Base MCP `send_calls`.

## Overview

SectorOne LP is **bin-based** (DLMM), not Uniswap tick-based. This skill:

1. Gathers pair, amounts, and user goals
2. Explains **bin step**, **bin range**, and **LB version** (v2 default)
3. Queries SectorOne docs for protocol specifics
4. Presents plan + **add-LP deep link** ([deep-links.md](../swap-planner/references/deep-links.md))

Requires LB **pair address** + **bin step** — from user URL, `list-pairs` CLI, or confirmed DexScreener hint.

```text
https://app.sectorone.xyz/liquidity/manual/:8453/add/v20/{lbPairAddress}/{binStep}
```

Example: https://app.sectorone.xyz/liquidity/manual/:8453/add/v20/0xa278be41d539f49bf52dbc919ae1572963cb55d9/10

## Workflow

### Step 1 — Gather LP intent

| Parameter | Required | Default | Example |
| --- | --- | --- | --- |
| Token A | Yes | — | WETH, USDC |
| Token B | Yes | — | USDC |
| Deposit amount | Yes | — | 1 ETH + USDC |
| Action | Yes | Add | Add / Remove |
| LB version | No | v2 | v2, v22 |

**Reject non-Base chains.** Use AskUserQuestion for missing action/pair (see plugin copy for JSON examples).

### Step 2 — Resolve and verify tokens

See [references/chains.md](../swap-planner/references/chains.md). Same web-discovered token warnings as swap-planner.

### Step 3 — Explain DLMM concepts

See [references/dlmm-bins.md](../swap-planner/references/dlmm-bins.md):

```bash
curl -sG "https://docs.sectorone.xyz/sectorone/welcome.md" \
  --data-urlencode "ask=How do DLMM bins and bin step work when adding liquidity on Base?"
```

### Step 4 — Suggest bin range (conceptual)

Offer narrow / medium / wide framing — exact bin IDs come from the app or CLI.

| Pair type | Suggested framing |
| --- | --- |
| Stable / correlated | Narrower bins |
| WETH / USDC | Medium width |
| Volatile | Wider bins; warn on IL |

### Step 5 — Add vs remove

- **Add:** app flow — pair → pool (bin step) → range → deposit → confirm
- **Remove:** app positions UI; calldata path → `dlmm-integration` + `read-position` / `build-remove-liquidity`

### Step 6 — Optional pool hints

Only if user asks. See [references/data-providers.md](../swap-planner/references/data-providers.md).

### Step 7 — Present LP plan

```markdown
## SectorOne Liquidity Plan (Base)

| Field | Value |
| --- | --- |
| Action | Add liquidity |
| Pair | WETH / USDC |
| Chain | Base (8453) |
| LB version | v2 (Joe 2.0) |
| Bin step | Pick deepest pool in app |
| Range | Medium around current price |

### Considerations
- IL if price leaves your bins
- No LP deep link — configure manually in app

### Execute
**Open SectorOne:** https://app.sectorone.xyz/liquidity/manual/:8453/add/v20/{pair}/{binStep}
```

## Additional resources

- [references/chains.md](../swap-planner/references/chains.md)
- [references/dlmm-bins.md](../swap-planner/references/dlmm-bins.md)
- [references/data-providers.md](../swap-planner/references/data-providers.md)
- [references/deep-links.md](../swap-planner/references/deep-links.md)
- [docs/BANKR.md](../../docs/BANKR.md)
