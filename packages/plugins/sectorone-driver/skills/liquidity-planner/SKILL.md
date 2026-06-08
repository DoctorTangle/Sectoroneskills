---
name: liquidity-planner
description: This skill should be used when the user asks to "provide liquidity SectorOne", "add liquidity DLMM", "LP on Joe Base", "liquidity on SectorOne", "DLMM bins", "bin step", "concentrated liquidity SectorOne", "remove liquidity SectorOne", "withdraw LP SectorOne", or mentions liquidity pools, LP positions, bins, or being a liquidity provider on SectorOne / Joe / Liquidity Book on Base mainnet. Plans DLMM liquidity context and directs the user to the SectorOne app. Does NOT require npm install. For unsigned add/remove calldata or Base MCP send_calls, use dlmm-integration instead.
allowed-tools: Read, Glob, Grep, Bash(curl:*), Bash(jq:*), WebFetch, WebSearch, AskUserQuestion
license: MIT
metadata:
  author: Sectoroneskills
  version: "0.2.0"
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
4. Presents a structured plan + app link — user executes in UI

**No private keys. No pre-filled LP deep links** (unlike Uniswap `positions/create?...`).

## Workflow

### Step 1 — Gather LP intent

| Parameter | Required | Default | Example |
| --- | --- | --- | --- |
| Token A | Yes | — | WETH, USDC |
| Token B | Yes | — | USDC |
| Deposit amount | Yes | — | 1 ETH + USDC |
| Action | Yes | Add | Add / Remove |
| LB version | No | v2 | v2, v22 |
| Bin step | No | User picks in app | 20, 50 |
| Bin range | No | Suggest conceptually | narrow / wide |

**Reject non-Base chains.**

**AskUserQuestion — action:**

```json
{
  "questions": [
    {
      "question": "What do you want to do?",
      "header": "Action",
      "options": [
        { "label": "Add liquidity", "description": "Deposit into DLMM bins" },
        { "label": "Remove liquidity", "description": "Withdraw existing position" },
        { "label": "Learn how LP works", "description": "Explain bins first" }
      ],
      "multiSelect": false
    }
  ]
}
```

**AskUserQuestion — common pairs:**

```json
{
  "questions": [
    {
      "question": "Which pair?",
      "header": "Pair",
      "options": [
        { "label": "WETH / USDC", "description": "Major Base pair" },
        { "label": "Custom pair", "description": "Specify two tokens" }
      ],
      "multiSelect": false
    }
  ]
}
```

### Step 2 — Resolve and verify tokens

See [references/chains.md](../../references/chains.md). Validate addresses (`^0x[a-fA-F0-9]{40}$`) before shell use.

Apply the same **web-discovered token warnings** as swap-planner.

### Step 3 — Explain DLMM concepts

Read [references/dlmm-bins.md](../../references/dlmm-bins.md) and summarize for the user:

- Liquidity is **per bin**; **active bin** is the current trading price
- **Bin step** defines pool granularity — multiple pools per pair possible
- Default **LB v2** on Base; **v2.1 not deployed**; **v22** only when explicitly v2.2

Query docs for detail:

```bash
curl -sG "https://docs.sectorone.xyz/sectorone/welcome.md" \
  --data-urlencode "ask=How do DLMM bins and bin step work when adding liquidity on Base?"
```

### Step 4 — Suggest bin range strategy (conceptual)

Present options with AskUserQuestion — **not exact bin IDs** (needs on-chain data / app):

```json
{
  "questions": [
    {
      "question": "How wide should your bin range be? (Current price set in app)",
      "header": "Range",
      "options": [
        { "label": "Narrow (higher fees, more management)", "description": "Around current price; good for stables/low volatility" },
        { "label": "Medium (balanced)", "description": "Typical for WETH/USDC" },
        { "label": "Wide (safer, lower fee density)", "description": "Volatile pairs; less rebalance risk" }
      ],
      "multiSelect": false
    }
  ]
}
```

**Guidance:**

| Pair type | Suggested framing |
| --- | --- |
| Stable / correlated | Narrower bins around peg |
| WETH / USDC | Medium width |
| Volatile / memecoin | Wider bins; warn on IL |

### Step 5 — Add vs remove liquidity

#### Add liquidity

User flow in app:

1. Open https://linktr.ee/SectorOneDEX → Base
2. Select pair and pool (**bin step** with deepest liquidity if unsure)
3. Set bin range in UI
4. Deposit amounts (ratio depends on range vs active bin)
5. Confirm transaction in wallet

#### Remove liquidity

| User need | This skill | Escalation |
| --- | --- | --- |
| "Withdraw my LP" (manual) | Explain bins + app link | — |
| Unsigned remove tx / Base MCP | Cannot | `dlmm-integration` |
| "Which bins am I in?" | Cannot | CLI `read-position` |

For remove requests, always mention: removing requires **bin IDs** from the position — visible in app or via CLI.

### Step 6 — Optional pool hints

Only if user asks about TVL, volume, or which pool to pick. See [references/data-providers.md](../../references/data-providers.md). Prefer directing user to compare pools **in the SectorOne app** over third-party data.

### Step 7 — Present LP plan

**Add liquidity template:**

```markdown
## SectorOne Liquidity Plan (Base)

| Field | Value |
| --- | --- |
| Action | Add liquidity |
| Pair | WETH / USDC |
| Chain | Base (8453) |
| LB version | v2 (Joe 2.0) — confirm in app |
| Bin step | Select pool with deepest liquidity in app |
| Range | Medium width around current price |
| Deposit | 0.5 WETH (+ matching USDC per app) |

### Considerations
- **Impermanent loss:** price leaving your bins → position may become one-sided
- **Bin management:** narrower ranges earn more when in range but need monitoring
- **No LP deep link:** enter pair, bin step, and range manually in the app

### Execute
**Open SectorOne:** https://linktr.ee/SectorOneDEX

### Need unsigned calldata?
`npx skills add DoctorTangle/Sectoroneskills --skill dlmm-integration` + clone https://github.com/DoctorTangle/dlmmskills
```

**Remove liquidity template:**

```markdown
## SectorOne Remove LP (Base)

| Field | Value |
| --- | --- |
| Action | Remove liquidity |
| Chain | Base (8453) |

### Steps
1. Open SectorOne app → Your positions
2. Select the WETH/USDC (or relevant) position
3. Choose bins / percentage to withdraw
4. Confirm in wallet

For programmatic remove calldata, use `dlmm-integration` (`read-position` → `build-remove-liquidity`).
```

## Important considerations

### Impermanent loss

DLMM concentrated bins amplify IL when price trends out of range. Disclose clearly for volatile assets.

### Bin step

Do not guess bin step from token symbols alone. User should confirm the pool in the app or provide the pool they already use.

### Capital

Depending on active bin vs selected range, deposits may require one or both tokens — the app shows the required ratio.

## Additional resources

- [references/chains.md](../../references/chains.md)
- [references/dlmm-bins.md](../../references/dlmm-bins.md)
- [references/data-providers.md](../../references/data-providers.md)
- [docs/BANKR.md](../../../../docs/BANKR.md)
