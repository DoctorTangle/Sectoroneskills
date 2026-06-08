# Data providers (Bankr-safe)

SectorOne has **no public Trading API** like Uniswap. Bankr driver skills use these sources only — no SDK, no `npm install`.

## Priority order

| Priority | Source | Use for |
| --- | --- | --- |
| 1 | On-chain RPC (`eth_getCode`, `eth_call`) | Token contract exists |
| 2 | SectorOne docs API | Protocol rules, LB versions, bins, vaults |
| 3 | Known token table | WETH, USDC on Base — see [chains.md](chains.md) |
| 4 | WebSearch | Unknown token symbols (then verify on-chain) |
| 5 | DexScreener | **Optional** — only when user asks price/liquidity; treat as hint |

Do **not** rely on DexScreener for execution, exact quotes, or calldata.

## SectorOne docs API

```bash
curl -sG "https://docs.sectorone.xyz/sectorone/welcome.md" \
  --data-urlencode "ask=Which LB version is default on Base mainnet?"
```

Use for: LB v2 vs v22, bin step concepts, farms/vaults, safety notes.

## Base RPC

Default public RPC: `https://base-rpc.publicnode.com`

**Verify contract:**

```bash
curl -s -X POST "$RPC" -H "Content-Type: application/json" \
  -d "$(jq -n --arg a "$ADDR" '{"jsonrpc":"2.0","method":"eth_getCode","params":[$a,"latest"],"id":1}')" \
  | jq -r '.result'
```

Result must not be `0x`.

**ERC-20 decimals (optional):**

```bash
# decimals() = 0x313ce567 — validate ADDR before use
curl -s -X POST "$RPC" -H "Content-Type: application/json" \
  -d "$(jq -n --arg a "$ADDR" '{"jsonrpc":"2.0","method":"eth_call","params":[$a,"0x313ce567","latest"],"id":1}')" \
  | jq -r '.result'
```

## DexScreener (optional, hint only)

Use **only** when the user explicitly wants a rough price or liquidity check.

```bash
# Token pairs on Base — dexId is unreliable for SectorOne; do not filter strictly
curl -s "https://api.dexscreener.com/token-pairs/v1/base/0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913" \
  | jq '[.[] | select(.chainId == "base")] | .[0:5] | map({
    dexId, pairAddress, priceUsd,
    liquidityUsd: .liquidity.usd,
    volume24h: .volume.h24
  })'
```

**Limitations:**

- May list non-SectorOne pools for the same token
- No bin-level depth or exact DLMM quote
- Missing pools are common for new/low-cap tokens

If DexScreener returns nothing useful, say so and direct the user to the SectorOne app.

## What requires CLI escalation

Exact SDK quotes, bin IDs, `build-swap`, `build-add-liquidity`, `build-remove-liquidity` → skill **`dlmm-integration`** + [dlmmskills](https://github.com/DoctorTangle/dlmmskills) CLI.
