# SectorOne app deep links

Base app: **https://app.sectorone.xyz**

## Add liquidity

```text
https://app.sectorone.xyz/liquidity/manual/:{chainId}/add/{lbAppVersion}/{lbPairAddress}/{binStep}
```

Example: [add LP on Base, bin step 10](https://app.sectorone.xyz/liquidity/manual/:8453/add/v20/0xa278be41d539f49bf52dbc919ae1572963cb55d9/10)

- `:8453` = Base chain id in path
- `v20` = default Joe 2.0 fee mode on Base (`v21` = autocompounding)
- `{lbPairAddress}` = LB **pair** contract (from `list-pairs` CLI or app URL)
- `{binStep}` = must match pair

## Swap

```text
https://app.sectorone.xyz/swap?inputCurrency={tokenIn}&outputCurrency={tokenOut}
```

Example USDC → WETH:

```text
https://app.sectorone.xyz/swap?inputCurrency=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913&outputCurrency=0x4200000000000000000000000000000000000006
```

Use WETH for ETH. Amount entered manually in app.

Full reference: same as `packages/plugins/sectorone-driver/references/deep-links.md`.
