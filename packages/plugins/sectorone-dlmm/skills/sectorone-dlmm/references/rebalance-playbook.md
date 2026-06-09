# Rebalance playbook (MCP + CLI)

Use this sequence when changing **distribution** (SPOT → CURVE → BID_ASK) or **bin count** on an existing SectorOne LP position on Base.

## Sequence

```text
1. read-pool              → activeId, pair context
2. discover-lp-bins       → bin IDs with LP (no guessing)
3. check-lp-approval      → ERC-1155 router approval status
4. build-remove-liquidity → --remove-all --batch-size 10
5. [wrap WETH if summary.needsWethWrap on add leg]
6. build-add-liquidity    → --distribution … --bin-count …
7. send_calls             → each remove batch, then add (approvals before add)
8. read-position          → verify (requires known bin IDs)
```

Or one shot: **`build-rebalance-liquidity`** (remove batches + add in `steps[]`).

## Commands

```bash
# 1–3: discovery
npm run sectorone -- read-pool --pair 0xPOOL --bin-step 10 --lb-version v2 --json
npm run sectorone -- discover-lp-bins --wallet 0xWALLET --pair 0xPOOL --scan-bins 60 --json
npm run sectorone -- check-lp-approval --wallet 0xWALLET --pair 0xPOOL --json

# 4: batched remove (≤10–15 bins per tx on Base)
npm run sectorone -- build-remove-liquidity \
  --wallet 0xWALLET --pair 0xPOOL \
  --token-x 0x4200…0006 --token-y 0x8335…2913 \
  --token-x-decimals 18 --token-y-decimals 6 \
  --bin-step 10 --lb-version v2 \
  --bin-ids "$(discovered ids)" \
  --remove-all --batch-size 10 --json

# 6: add new shape
npm run sectorone -- build-add-liquidity \
  --wallet 0xWALLET \
  --token-x 0x4200…0006 --token-y 0x8335…2913 \
  --token-x-decimals 18 --token-y-decimals 6 \
  --amount-x 0.000254 --amount-y 1 \
  --bin-step 10 --lb-version v2 \
  --distribution BID_ASK --bin-count 41 --json
```

## `--bin-count` (all distributions)

| Distribution | `--bin-count` | Without flag |
| --- | --- | --- |
| SPOT | Uniform range centered on `activeId` | SDK default **11 bins** |
| CURVE | Gaussian via `getCurveDistributionFromBinRange` | 11 bins |
| BID_ASK | Edge-weighted via `getBidAskDistributionFromBinRange` | 11 bins |

## Remove approvals

| Type | Required? |
| --- | --- |
| ERC-20 | **No** for remove |
| ERC-1155 on LB pair | **`setApprovalForAll(router, true)`** once per pair — CLI emits this call when needed |

## Native ETH on Base v2

**Do not use `--native-x` / `--native-y` with `--lb-version v2` on Base.** Router v2.0 has no `addLiquidityNATIVE`. Wrap ETH → WETH first; use normal `addLiquidity` / `removeLiquidity`.

## Add after approvals (critical)

1. Wrap WETH if `summary.needsWethWrap`
2. Build calls → send **approvals** → wait for receipt
3. **Rebuild** add calls → send **only** the liquidity call(s)

## Local execution (optional)

| npm script | Flow |
| --- | --- |
| `position:execute` | Add only |
| `position:withdraw` | Remove only (`BIN_IDS` or auto `discover-lp-bins`) |
| `position:rebalance` | Remove batches + add |

For `PRIVATE_KEY` workflows (not Base MCP): see dlmmskills `.env.example` — `DRY_RUN=false`. Never put keys in skills or commits.

**Unsigned withdraw (MCP/Bankr):** `build-remove-liquidity --remove-all --batch-size 10 --json` → `send_calls` or Bankr submit per batch.

## Windows

PowerShell: use `;` instead of `&&` between commands.

## Troubleshooting

| Error | Likely cause | Fix |
| --- | --- | --- |
| `transfer amount exceeds allowance` | Stale calldata / wrap after build | Wrap → rebuild → send |
| `execution reverted` (remove, many bins) | Too many bins per tx | `--batch-size 10` |
| `NATIVE_LIQUIDITY_UNSUPPORTED` | `--native-x` on v2 Base | Wrap WETH, omit native flags |
| `required option '--bin-ids'` | `read-position` without bins | Run `discover-lp-bins` first |
| `NO_LP_IN_BIN` | Wrong bin IDs | Re-run discovery with larger `--scan-bins` |
