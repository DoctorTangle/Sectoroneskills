# SectorOne app deep links

Base app: **https://app.sectorone.xyz** ([official links](https://docs.sectorone.xyz/info/official-links.md))

Use these like Uniswap `app.uniswap.org/swap?...` — pre-fill the UI; user still connects wallet and confirms.

## Add liquidity (manual DLMM)

**Template:**

```text
https://app.sectorone.xyz/liquidity/manual/:{chainId}/add/{lbAppVersion}/{lbPairAddress}/{binStep}
```

**Example (Base, bin step 10):**

```text
https://app.sectorone.xyz/liquidity/manual/:8453/add/v20/0xa278be41d539f49bf52dbc919ae1572963cb55d9/10
```

| Segment | Value | Notes |
| --- | --- | --- |
| `chainId` | `8453` | Base mainnet — literal `:8453` in path |
| action | `add` | Manual add-liquidity flow |
| `lbAppVersion` | `v20` | Default for Joe 2.0 / claimable-fee pools on Base; `v21` = autocompounding fee mode in app |
| `lbPairAddress` | `0x…` | **LB pair contract** (not token address) |
| `binStep` | e.g. `10`, `25`, `50` | Must match the pair |

Optional query (app internal): `?showTop=true`

### Resolving `lbPairAddress` + `binStep`

| Method | When |
| --- | --- |
| User pastes app URL | Parse path segments |
| **dlmmskills CLI** | `list-pairs --token-in … --token-out … --lb-version v2 --json` → `pairs[].pair` + `pairs[].binStep` |
| DexScreener | `pairAddress` hint only — confirm on SectorOne |

**CLI example (USDC → WETH, v2 on Base):**

```bash
npm run sectorone -- list-pairs \
  --token-in 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 \
  --token-out 0x4200000000000000000000000000000000000006 \
  --token-in-decimals 6 --token-out-decimals 18 \
  --lb-version v2 --json
```

Pick the pool (pair + bin step) the user wants — often moderate bin step (e.g. 10–50) for major pairs.

**Build link:**

```text
https://app.sectorone.xyz/liquidity/manual/:8453/add/v20/{pair}/{binStep}
```

### App vs CLI version names

| dlmmskills CLI | App URL segment | Typical Base usage |
| --- | --- | --- |
| `v2` | `v20` (claimable fees) or `v21` (autocompounding) | Most Joe 2.0 pools |
| `v22` | Confirm in app / pool page | v2.2 factory pools |

When unsure, use **`v20`** (matches common Base liquidity links).

## Remove liquidity (manual DLMM)

**Template:**

```text
https://app.sectorone.xyz/liquidity/manual/:{chainId}/remove/{lbAppVersion}/{lbPairAddress}/{binStep}
```

**Example (Base, bin step 10):**

```text
https://app.sectorone.xyz/liquidity/manual/:8453/remove/v20/0xa278be41d539f49bf52dbc919ae1572963cb55d9/10
```

Same path segments as **add** — only the action changes from `add` to `remove`. User still selects bins / percentage in the app after opening the link.

For unsigned remove calldata / Base MCP, escalate to **`dlmm-integration`** (`read-position` → `build-remove-liquidity`).

## Swap

**Template (query params — used inside the app):**

```text
https://app.sectorone.xyz/swap?inputCurrency={tokenIn}&outputCurrency={tokenOut}
```

**Example (100 USDC → WETH on Base):**

```text
https://app.sectorone.xyz/swap?inputCurrency=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913&outputCurrency=0x4200000000000000000000000000000000000006
```

| Parameter | Value |
| --- | --- |
| `inputCurrency` | ERC-20 address or native token id the app accepts (use **WETH** address for ETH swaps) |
| `outputCurrency` | ERC-20 address |

Amount is **not** reliably pre-filled via URL — user enters amount in the app after opening the link.

Single-sided output hint (app internal):

```text
https://app.sectorone.xyz/swap?outputCurrency=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
```

## Other app links

| Flow | Example |
| --- | --- |
| Vault list (Base) | `https://app.sectorone.xyz/makervault/list/:8453` |
| Linktree (fallback) | https://linktr.ee/SectorOneDEX |

## Bankr output format

Always show the **full HTTPS URL** prominently (Bankr may not open browsers):

```markdown
**Open in SectorOne (add):** https://app.sectorone.xyz/liquidity/manual/:8453/add/v20/0x…/10

**Open in SectorOne (remove):** https://app.sectorone.xyz/liquidity/manual/:8453/remove/v20/0x…/10
```

Validate addresses before interpolating. Lowercase addresses in URLs are usually fine.
