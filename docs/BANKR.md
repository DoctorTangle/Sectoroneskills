# Bankr Bot Compatibility

Bankr bots ([skills.bankr.bot](https://skills.bankr.bot)) work well with Uniswap because Uniswap splits **lightweight driver skills** from **heavy trading integration**. SectorOne now follows the same pattern.

## Install skills (Skills CLI)

```bash
# Bankr-safe — no SDK, no npm install
npx skills add DoctorTangle/Sectoroneskills --skill swap-planner
npx skills add DoctorTangle/Sectoroneskills --skill liquidity-planner

# Full calldata (needs git + npm install in dlmmskills repo)
npx skills add DoctorTangle/Sectoroneskills --skill dlmm-integration
```

List discoverable skills:

```bash
npx skills add DoctorTangle/Sectoroneskills --list
```

## Which skill when?

| User goal | Skill | Needs CLI? |
| --- | --- | --- |
| "Swap on SectorOne" (human executes in app) | `swap-planner` | No |
| "Add/remove LP" (plan + app) | `liquidity-planner` | No |
| Base MCP `send_calls`, exact SDK quote | `dlmm-integration` | Yes |
| Cursor / Claude Code all-in-one | `sectorone-dlmm` | Yes |

## Why the old single skill failed on Bankr

1. **`npm install` runs preinstall** — clones SectorOne into `_sectorone-ref/` (needs **git**).
2. **`file:` dependencies** — SDK is not on npm registry; hoisted build needs **tsup** at root.
3. **No HTTP quote API** — unlike Uniswap Trading API; everything goes through the CLI.
4. **One skill, two phases** — Bankr often installs markdown only and never clones the repo.
5. **Missing Bankr frontmatter** — no `allowed-tools`, no trigger phrases, no `metadata.version`.

## Plugin layout (Uniswap-style)

```text
packages/plugins/
  sectorone-driver/     # Bankr-safe planners
    skills/swap-planner/
    skills/liquidity-planner/
  sectorone-trading/      # CLI + Base MCP
    skills/dlmm-integration/
    scripts/check-cli.sh
```

Legacy umbrella: `skills/sectorone-dlmm/` (Cursor + Base MCP all-in-one onboarding).

## Limitations vs Uniswap driver

- **Swap deep links** pre-fill tokens via query params; **amount** is still entered in the app (Uniswap can pass `value=`).
- **Add-LP deep links** pre-fill chain, pool, and bin step: `app.sectorone.xyz/liquidity/manual/:8453/add/v20/{pair}/{binStep}` — see [references/deep-links.md](../packages/plugins/sectorone-driver/references/deep-links.md).
- **Remove LP deep link:** `app.sectorone.xyz/liquidity/manual/:8453/remove/v20/{pair}/{binStep}` — same segments as add, action `remove`.
- Exact on-chain quotes still require **dlmmskills CLI** or a future quote API.

## Publishing to skills.bankr.bot

After merge to `main`, skills are picked up from GitHub by the Skills CLI / Bankr index (same as Uniswap/uniswap-ai). Ensure frontmatter includes `name`, `description`, `license`, and `metadata.author`.
