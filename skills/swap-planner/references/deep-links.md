# SectorOne app deep links

Base app: **https://app.sectorone.xyz**

## Add liquidity

```text
https://app.sectorone.xyz/liquidity/manual/:{chainId}/add/{lbAppVersion}/{lbPairAddress}/{binStep}
```

Example: https://app.sectorone.xyz/liquidity/manual/:8453/add/v20/0xa278be41d539f49bf52dbc919ae1572963cb55d9/10

## Remove liquidity

```text
https://app.sectorone.xyz/liquidity/manual/:{chainId}/remove/{lbAppVersion}/{lbPairAddress}/{binStep}
```

Example: https://app.sectorone.xyz/liquidity/manual/:8453/remove/v20/0xa278be41d539f49bf52dbc919ae1572963cb55d9/10

Same segments as add — action is `remove` instead of `add`.

## Swap

```text
https://app.sectorone.xyz/swap?inputCurrency={tokenIn}&outputCurrency={tokenOut}
```

Full reference: `packages/plugins/sectorone-driver/references/deep-links.md`.
