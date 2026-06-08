# Bankr wallet submit (SectorOne calldata)

Execute pre-built SectorOne transactions with the **Bankr hosted wallet** ([Submit Endpoint](https://docs.bankr.chat/integrations/agent-api/submit-endpoint/), [arbitrary transaction](https://github.com/BankrBot/openclaw-skills/blob/main/bankr/references/arbitrary-transaction.md)).

## Prerequisites

| Variable | Purpose |
| --- | --- |
| `BANKR_API_KEY` | API key with **write** access (`bk_…`, not read-only) |
| `BASE_RPC_URL` | Required for dlmmskills CLI live reads |
| `SECTORONE_CLI_ROOT` | Path to cloned [dlmmskills](https://github.com/DoctorTangle/dlmmskills) (optional if cwd is repo root) |

Base URL: `https://api.bankr.bot`

## Get Bankr wallet (Base)

```bash
curl -s https://api.bankr.bot/agent/user \
  -H "X-API-Key: $BANKR_API_KEY" \
  | jq -r '.wallets[] | select(.chainId == 8453 or .chain == "base") | .address' | head -1
```

Use this address as `--wallet` for all `build-*` CLI commands. Field names may vary — inspect full JSON if needed.

## Map CLI call → Bankr submit

dlmmskills JSON `calls[]` items look like:

```json
{ "to": "0x…", "data": "0x…", "value": "0x0" }
```

Submit **each call in order** (approvals before swaps/addLiquidity):

```bash
curl -s -X POST https://api.bankr.bot/agent/submit \
  -H "X-API-Key: $BANKR_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg to "$TO" \
    --arg data "$DATA" \
    --arg value "${VALUE:-0x0}" \
    '{
      transaction: { to: $to, data: $data, value: $value, chainId: 8453 },
      waitForConfirmation: true
    }')"
```

Or use `scripts/submit-via-bankr.sh` in this plugin.

## Rules

1. **Never** submit without showing `summary` from CLI JSON to the user first.
2. **Pool create** requires `--confirm-create` on CLI and explicit user consent.
3. **Remove all** requires explicit user confirmation before `--remove-all`.
4. Stop on first failed submit; do not continue the sequence.
5. Log each tx hash returned by Bankr.
6. Insufficient gas or token balance → report clearly (Bankr wallet must hold tokens + ETH for gas).

## Escalation

| Need | Skill |
| --- | --- |
| Deep link only (no execute) | `liquidity-planner` / `swap-planner` |
| Base MCP `send_calls` | `dlmm-integration` |
| Swap execute via Bankr native routing | Bankr prompt API (0x — not SectorOne DLMM) |
