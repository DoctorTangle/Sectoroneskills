# SectorOne on Base (chainId 8453)

SectorOne DLMM on **Base mainnet only** for these Bankr skills. Reject other chains politely and offer Base.

| Item | Value |
| --- | --- |
| Chain | Base mainnet |
| Chain ID | `8453` |
| MCP chain name | `base` |
| RPC (public) | `https://base-rpc.publicnode.com` |
| Native ETH | User-facing: ETH; on-chain swaps use **WETH** |
| WETH | `0x4200000000000000000000000000000000000006` |
| USDC | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| LB Router v2.0 | `0xd4f937581650A2d6e416Dd9EF5372C1672422843` |
| LB Router v2.2 | `0x87aC1EB5596D47f6fd7d0D17bEE233783dB5CfEC` |
| DexLens | `0x0Ff91bA6928F5Bb700662D72B8290FEa7A5a96D1` |

## Common tokens (Base)

| Symbol | Address |
| --- | --- |
| WETH | `0x4200000000000000000000000000000000000006` |
| USDC | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| USDbC (legacy) | `0xd9aAEc86B65D86f65A760cF351A120Ae391cBA39` |
| DAI | `0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb` |
| cbETH | `0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22` |

For unknown symbols: WebSearch → verify address with `eth_getCode` → warn if web-discovered.

## Protocol notes

- Most Base liquidity: **LB v2.0 (Joe 2.0)**
- **v2.1 is not on Base**
- Use **v22** only for v2.2-factory pools

## App entry

**Primary:** https://app.sectorone.xyz  
**Linktree (fallback):** https://linktr.ee/SectorOneDEX

Deep links: [deep-links.md](deep-links.md) — swap query params + liquidity manual path URLs.

## Docs API

```text
GET https://docs.sectorone.xyz/sectorone/welcome.md?ask=<url-encoded question>
```

Example:

```bash
curl -sG "https://docs.sectorone.xyz/sectorone/welcome.md" \
  --data-urlencode "ask=Which LB version is default on Base?"
```
