# DLMM bins on SectorOne (Base)

SectorOne uses **Liquidity Book (LB / DLMM)** — liquidity lives in discrete **price bins**, not Uniswap-style tick ranges.

## Core concepts

| Term | Meaning |
| --- | --- |
| **Bin** | Price bucket; swaps move the **active bin** as liquidity is consumed |
| **Bin step** | Spacing between bins (basis points). Same token pair can have multiple pools with different bin steps |
| **Active bin** | Current trading price bin; swap slippage depends on depth **in and around** this bin |
| **LB version** | Factory/router generation — on Base, **v2 (Joe 2.0)** holds most liquidity |

## LB versions on Base

| Version | When to use | Router (see chains.md) |
| --- | --- | --- |
| **v2** (Joe 2.0) | Default — most pairs | LB Router v2.0 |
| **v22** (v2.2 factory) | Only if user/pool is explicitly v2.2 | LB Router v2.2 |
| **v2.1** | **Not deployed on Base** | — |

When unsure, recommend **v2** and tell the user to confirm the pool in the app.

## Bin step selection (planning guide)

| Bin step | Typical use | Trade-off |
| --- | --- | --- |
| Lower (e.g. 1–10) | Stable or correlated pairs | Tighter bins, more active management |
| Medium (e.g. 20–50) | Major pairs (WETH/USDC) | Common default range |
| Higher (e.g. 80–100) | Volatile / memecoins | Wider effective steps, less precision |

**Bankr planner cannot pick the exact bin step without on-chain pool data.** Ask the user which pool they use in the app, or suggest they pick the pool with the **deepest liquidity** for their pair in the SectorOne UI.

Query docs when explaining:

```bash
curl -sG "https://docs.sectorone.xyz/sectorone/welcome.md" \
  --data-urlencode "ask=How do bin step and active bin affect liquidity on SectorOne?"
```

## Add liquidity (user flow)

1. Choose token pair on **Base** in SectorOne app
2. Select pool / **bin step** (or create — advanced)
3. Choose **price range** as bin IDs or visual range in UI
4. Deposit token X and/or Y — ratio depends on active bin vs selected range
5. Confirm in app (user wallet signs)

## Remove liquidity

| Surface | Capability |
| --- | --- |
| SectorOne app | User selects position and removes in UI |
| Bankr driver skill | Plan + link to app only |
| `dlmm-integration` + CLI | `read-position` → `build-remove-liquidity` with `--bin-ids` |

Always escalate remove-LP calldata requests to **`dlmm-integration`**.

## DLMM vs Uniswap LP (user messaging)

| Uniswap v3 | SectorOne DLMM |
| --- | --- |
| Tick range | Bin range |
| Fee tier (0.05%, 0.3%, …) | Bin step + pool version |
| Concentrated around price | Liquidity per bin; active bin moves on swaps |
| Deep link to pre-filled range | **No documented deep link** — use app |

## Impermanent loss / range risk

- If price moves **outside** deposited bins, the position stops earning fees and may be 100% one token
- Narrower bin ranges → higher fee capture when in range, more rebalance risk
- Warn on volatile pairs and large single-sided deposits
