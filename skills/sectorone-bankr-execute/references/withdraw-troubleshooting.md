# Withdraw (remove liquidity) — troubleshooting

Most on-chain **reverts** on `removeLiquidity` come from using the **wrong LB factory/router version** or **wrong position parameters**. Fix these **before** Bankr submit.

## 1. LB version: v2 vs v22 (most common)

SectorOne on Base has **two** router generations:

| CLI `--lb-version` | Router (check in JSON `summary.router`) |
| --- | --- |
| `v2` (Joe 2.0) | `0xd4f937581650A2d6e416Dd9EF5372C1672422843` |
| `v22` (v2.2 factory) | `0x87aC1EB5596D47f6fd7d0D17bEE233783dB5CfEC` |

**Symptom:** Bankr submit succeeds but tx **reverts** on `LBRouter v2.0` while user’s pool is **v2.2** (or the reverse).

**Rule:** Never assume `v2` from app URL `v20` alone. The app segment is a **UI mode**, not a guaranteed factory mapping.

### Resolve version (mandatory before `build-remove-liquidity`)

Given **pair address** from app URL or user:

```bash
PAIR=0xYourPairAddress   # lowercase ok
TOKEN_IN=0x…             # token A
TOKEN_OUT=0x…            # token B
IN_DEC=18
OUT_DEC=18

for V in v2 v22; do
  npm run sectorone -- list-pairs \
    --token-in "$TOKEN_IN" --token-out "$TOKEN_OUT" \
    --token-in-decimals "$IN_DEC" --token-out-decimals "$OUT_DEC" \
    --lb-version "$V" --json \
  | jq -e --arg p "${PAIR,,}" \
    '.pairs[] | select(.pair | ascii_downcase == $p) | {version: "'"$V"'", pair, binStep}'
done
```

Whichever query returns a row → use that `--lb-version` for `build-remove-liquidity`.

Or run: `bash scripts/resolve-lb-version.sh --pair "$PAIR" …`

After `build-remove-liquidity --json`, **confirm** `summary.router` matches the table above.

---

## 2. Bin step must match the pool

`--bin-step` must be the pool’s bin step (from app URL last segment or `list-pairs`).

Wrong bin step → wrong pair resolution or revert.

---

## 3. Bin IDs must hold the user’s LP

`build-remove-liquidity` needs **exact bin IDs** where the Bankr wallet has LP shares.

| Source | How |
| --- | --- |
| User / SectorOne app | Position detail shows bin range |
| `read-position` | Only works if you already know candidate `--bin-ids` |
| Deep link | `…/remove/v20/{pair}/{binStep}` — user picks bins in UI (no bin IDs in URL) |

Use **`--remove-all`** (with user OK) so CLI reads LP balances per bin via RPC.

If CLI returns `NO_LP_IN_BIN` → wrong bin IDs or wrong wallet / pair / version.

---

## 4. Token addresses + decimals

Pass the **same token addresses** as the pool (from app or pair page). Decimals must be correct.

Use `--pair 0x…` plus tokens + `--bin-step` when token order is ambiguous.

---

## 5. Slippage / partial remove

Default output slippage is 50 bps. Extreme pool state can cause revert if mins are too high — retry with `--amount-slippage-bps 100` only after user confirms.

---

## 6. When to stop and use the app

Escalate to **liquidity-planner** remove deep link if:

- Version cannot be resolved (`list-pairs` empty for both v2 and v22)
- Bin IDs unknown and user cannot provide them
- Repeated reverts after correct `--lb-version` + bins

```text
https://app.sectorone.xyz/liquidity/manual/:8453/remove/v20/{pair}/{binStep}
```

---

## Checklist (Flow C)

1. Resolve **`--lb-version`** (`v2` or `v22`) from pair address  
2. Confirm **`--bin-step`**  
3. Get **`--bin-ids`** (user or `--remove-all` after IDs known)  
4. `build-remove-liquidity --wallet "$WALLET" … --json`  
5. Verify `summary.router` + show `summary` to user  
6. Single Bankr submit (usually one `removeLiquidity` call)
