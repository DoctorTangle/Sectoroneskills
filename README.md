# SectorOne Agent Skills

Agent skills for [SectorOne DLMM](https://sectorone.xyz) on **Base mainnet** — Bankr-safe planners, Base MCP calldata integration, and Cursor/Claude Code onboarding.

**CLI and SDK tooling** live in a separate repository: [DoctorTangle/dlmmskills](https://github.com/DoctorTangle/dlmmskills).

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
| Base MCP `send_calls`, exact SDK quote | `dlmm-integration` | Yes |
| Cursor / Claude Code all-in-one | `sectorone-dlmm` | Yes |

See [docs/BANKR.md](docs/BANKR.md) for the Uniswap-style driver vs trading split and Bankr compatibility notes.

## Plugin layout (Claude Code)

```text
packages/plugins/
  sectorone-driver/     # Bankr-safe planners
  sectorone-trading/    # CLI + Base MCP (check-cli.sh preflight)
```

Legacy layouts: `skills/base-mcp/` (deprecated), `skills/sectorone-dlmm/` (canonical umbrella).

Driver reference docs (`chains`, `dlmm-bins`, `data-providers`): `packages/plugins/sectorone-driver/references/`

## Base MCP upstream

Thin plugin for a future [base/skills](https://github.com/base/skills) PR: [contrib/base-skills/](contrib/base-skills/).

## License

MIT
