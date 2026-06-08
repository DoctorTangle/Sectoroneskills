# Bankr wallet submit (SectorOne calldata)

Execute pre-built SectorOne transactions with the **Bankr hosted wallet** ([Submit Endpoint](https://docs.bankr.chat/integrations/agent-api/submit-endpoint/), [arbitrary transaction](https://github.com/BankrBot/openclaw-skills/blob/main/bankr/references/arbitrary-transaction.md)).

## Prerequisites

| Variable | Purpose |
| --- | --- |
| `BANKR_API_KEY` | API key with **write** access (`bk_…`, not read-only) |
| `BASE_RPC_URL` | Required for dlmmskills CLI live reads |
| `SECTORONE_CLI_ROOT` | Path to cloned [dlmmskills](https://github.com/DoctorTangle/dlmmskills) |

Base URL: `https://api.bankr.bot`

## Get Bankr wallet (Base)

```bash
curl -s https://api.bankr.bot/agent/user \
  -H "X-API-Key: $BANKR_API_KEY" \
  | jq -r '.wallets[] | select(.chainId == 8453 or .chain == "base") | .address' | head -1
```

## Submit each CLI call

```bash
bash scripts/submit-via-bankr.sh "$TO" "$DATA" "${VALUE:-0x0}"
```

See full curl example in plugin copy at `packages/plugins/sectorone-bankr-execute/references/bankr-submit.md`.

## Rules

1. Show CLI `summary` before submit.
2. `--confirm-create` + user OK for new pools.
3. `--remove-all` only with explicit user OK.
4. Stop on first failed submit.
