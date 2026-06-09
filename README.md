# SectorOne Agent Skills

Agent skills for [SectorOne DLMM](https://sectorone.xyz) on **Base mainnet** — Bankr-safe planners, Base MCP calldata integration, and Cursor/Claude Code onboarding.

**CLI and SDK tooling** live in a separate repository: [DoctorTangle/dlmmskills](https://github.com/DoctorTangle/dlmmskills).

> **Important:** Agents need **both** — install skills from this repo **and** clone/build dlmmskills for calldata commands. The CLI repo alone does not install agent playbooks.

## Install (Skills CLI)

List discoverable skills:

```bash
npx skills add DoctorTangle/Sectoroneskills --list
```

### Bankr bots (no npm install, no SDK)

```bash
npx skills add DoctorTangle/Sectoroneskills --skill swap-planner
npx skills add DoctorTangle/Sectoroneskills --skill liquidity-planner
```

### Bankr wallet execute (pool / deposit / withdraw)

Requires [dlmmskills](https://github.com/DoctorTangle/dlmmskills) CLI + `BANKR_API_KEY` (write):

```bash
npx skills add DoctorTangle/Sectoroneskills --skill sectorone-bankr-execute
```

### Full calldata (Base MCP `send_calls`)

Requires cloning and building the CLI from [dlmmskills](https://github.com/DoctorTangle/dlmmskills):

```bash
npx skills add DoctorTangle/Sectoroneskills --skill dlmm-integration
git clone https://github.com/DoctorTangle/dlmmskills.git
cd dlmmskills && npm install
```

### Cursor / Claude Code (all-in-one)

```bash
npx skills add DoctorTangle/Sectoroneskills --skill sectorone-dlmm -a cursor -y
```

Then clone [dlmmskills](https://github.com/DoctorTangle/dlmmskills) for quotes and unsigned calldata.

## Which skill when?

| User goal | Skill | Needs CLI? |
| --- | --- | --- |
| Swap on SectorOne (human executes in app) | `swap-planner` | No |
| Add/remove LP (plan + app) | `liquidity-planner` | No |
| Create pool / LP deposit / withdraw (Bankr wallet) | `sectorone-bankr-execute` | CLI + API key |
| Base MCP `send_calls`, exact SDK quote | `dlmm-integration` | Yes |
| Cursor / Claude Code all-in-one | `sectorone-dlmm` | Yes |

See [docs/BANKR.md](docs/BANKR.md) for the Uniswap-style driver vs trading split and Bankr compatibility notes.

## Plugin layout (Claude Code)

```text
packages/plugins/
  sectorone-driver/     # Bankr-safe planners
  sectorone-trading/    # dlmm-integration (CLI + Base MCP)
  sectorone-bankr-execute/
  sectorone-dlmm/       # Full umbrella skill (discoverable via npx skills)
```

`skills/sectorone-dlmm/` is the **canonical source**; sync to `packages/plugins/sectorone-dlmm/skills/` when editing (required for `npx skills add --skill sectorone-dlmm`).

Legacy: `skills/base-mcp/` (deprecated).

Driver reference docs (`chains`, `dlmm-bins`, `data-providers`): `packages/plugins/sectorone-driver/references/`

## Base MCP upstream

Thin plugin for a future [base/skills](https://github.com/base/skills) PR: [contrib/base-skills/](contrib/base-skills/).

## License

MIT
