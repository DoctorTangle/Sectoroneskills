---
name: liquidity-planner
description: This skill should be used when the user asks to "provide liquidity SectorOne", "add liquidity DLMM", "LP on Joe Base", "liquidity on SectorOne", "DLMM bins", "bin step", "concentrated liquidity SectorOne", "remove liquidity SectorOne", "withdraw LP SectorOne", or mentions liquidity pools, LP positions, bins, or being a liquidity provider on SectorOne / Joe / Liquidity Book on Base mainnet. Plans DLMM liquidity context and generates app.sectorone.xyz add/remove LP deep links. Does NOT require npm install. For unsigned add/remove calldata or Base MCP send_calls, use dlmm-integration instead.
allowed-tools: Read, Glob, Grep, Bash(curl:*), Bash(jq:*), WebFetch, WebSearch, AskUserQuestion
license: MIT
metadata:
  author: Sectoroneskills
  version: "0.2.2"
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
4. Presents a structured plan + **add-LP deep link** — user executes in UI

**No private keys.**

Generate URLs per [references/deep-links.md](../../references/deep-links.md). Requires **LB pair address** + **bin step** (see below).

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
| Withdraw LP in app | Generate **remove deep link** (same pair/bin step as add) | — |
| Unsigned remove tx / Base MCP | Cannot | `dlmm-integration` |
| "Which bins am I in?" | Cannot | CLI `read-position` |

**Remove deep link** (when pair + bin step known):

```text
https://app.sectorone.xyz/liquidity/manual/:8453/remove/v20/{lbPairAddress}/{binStep}
```

**Example:**

```text
https://app.sectorone.xyz/liquidity/manual/:8453/remove/v20/0xa278be41d539f49bf52dbc919ae1572963cb55d9/10
```

User still picks bins / withdrawal amount in the app. For programmatic remove, use `read-position` → `build-remove-liquidity`.

### Step 6 — Resolve pair address + bin step (for deep link)

Required for add-LP deep links. See [references/deep-links.md](../../references/deep-links.md).

| Source | How |
| --- | --- |
| User pasted app URL | Parse `/liquidity/manual/:8453/add/v20/{pair}/{binStep}` |
| **dlmmskills CLI** (best) | `list-pairs --token-in … --token-out … --lb-version v2 --json` |
| DexScreener | `pairAddress` hint — confirm pool is SectorOne |

**Default app path segment on Base:** `v20` (Joe 2.0 claimable-fee pools). Use `v21` only if user targets autocompounding fee pools.

**Build add-LP link:**

```text
https://app.sectorone.xyz/liquidity/manual/:8453/add/v20/{lbPairAddress}/{binStep}
```

**Example:**

```text
https://app.sectorone.xyz/liquidity/manual/:8453/add/v20/0xa278be41d539f49bf52dbc919ae1572963cb55d9/10
```

If pair/bin step unknown, ask the user which pool they use in the app — do **not** guess pair addresses.

### Step 7 — Optional pool hints

Only if user asks about TVL, volume, or which pool to pick. See [references/data-providers.md](../../references/data-providers.md). Prefer directing user to compare pools **in the SectorOne app** over third-party data.

### Step 8 — Present LP plan

**Add liquidity template:**

```markdown
## SectorOne Liquidity Plan (Base)

| Field | Value |
| --- | --- |
| Action | Add liquidity |
| Pair | WETH / USDC |
| Chain | Base (8453) |
| LB version | v2 (Joe 2.0) — confirm in app |
| Bin step | 10 |
| Deep link | https://app.sectorone.xyz/liquidity/manual/:8453/add/v20/0xa278be41d539f49bf52dbc919ae1572963cb55d9/10 |

### Considerations
- **Impermanent loss:** price leaving your bins → position may become one-sided
- **Bin management:** narrower ranges earn more when in range but need monitoring
- Set bin range and deposit amounts in the app after opening the link

### Execute
**Open SectorOne:** https://app.sectorone.xyz/liquidity/manual/:8453/add/v20/0xa278be41d539f49bf52dbc919ae1572963cb55d9/10

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
| Pair address | 0xa278be41d539f49bf52dbc919ae1572963cb55d9 |
| Bin step | 10 |
| LB app version | v20 |

### Steps
1. Open remove deep link (pool pre-selected)
2. Connect wallet → select position bins / amount to withdraw
3. Confirm in wallet

### Execute
**Open SectorOne:** https://app.sectorone.xyz/liquidity/manual/:8453/remove/v20/0xa278be41d539f49bf52dbc919ae1572963cb55d9/10

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
- [references/deep-links.md](../../references/deep-links.md)
- [docs/BANKR.md](../../../../docs/BANKR.md)
