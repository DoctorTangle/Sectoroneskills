# End-to-end dry-run: validate SectorOne CLI JSON for Bankr execute flows.
# Does NOT call Bankr /agent/submit. BANKR_API_KEY is optional.
$ErrorActionPreference = "Stop"

$script:Pass = 0
$script:Fail = 0
$script:Skip = 0

function Write-Pass([string]$Msg) { Write-Host "PASS: $Msg"; $script:Pass++ }
function Write-Fail([string]$Msg) { Write-Host "FAIL: $Msg" -ForegroundColor Red; $script:Fail++ }
function Write-Skip([string]$Msg) { Write-Host "SKIP: $Msg" -ForegroundColor Yellow; $script:Skip++ }

$Root = $env:SECTORONE_CLI_ROOT
if (-not $Root) {
  if ((Test-Path "./package.json") -and (Select-String -Path "./package.json" -Pattern '"sectorone"' -Quiet)) {
    $Root = (Get-Location).Path
  } elseif ((Test-Path "dlmmskills/package.json")) {
    $Root = (Resolve-Path "dlmmskills").Path
  }
}

if (-not $Root -or -not (Test-Path "$Root/package.json")) {
  Write-Fail "Clone https://github.com/DoctorTangle/dlmmskills and run npm install. Set SECTORONE_CLI_ROOT if needed."
  exit 1
}

if (-not (Test-Path "$Root/_sectorone-ref/packages/v2")) {
  Write-Fail "Run npm install in $Root (missing SDK)."
  exit 1
}

if (-not $env:BASE_RPC_URL) {
  $env:BASE_RPC_URL = "https://base-rpc.publicnode.com"
}

$Usdc = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
$Weth = "0x4200000000000000000000000000000000000006"
$Dai = "0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb"
$DryWallet = if ($env:SECTORONE_DRY_RUN_WALLET) { $env:SECTORONE_DRY_RUN_WALLET } else { "0x0000000000000000000000000000000000000001" }
$LpWallet = $env:SECTORONE_DRY_RUN_LP_WALLET
$BinStep = if ($env:SECTORONE_DRY_RUN_BIN_STEP) { $env:SECTORONE_DRY_RUN_BIN_STEP } else { "25" }

function Invoke-SectorOne {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$CliArgs)
  Push-Location $Root
  try {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $raw = & npx tsx src/cli/sectorone.ts @CliArgs 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    return @{ ExitCode = $code; Output = ($raw | Out-String).Trim() }
  } finally {
    Pop-Location
  }
}

function Test-BankrPayload {
  param([string]$Label, [string]$JsonText, [string]$Action)
  try {
    $obj = $JsonText | ConvertFrom-Json
  } catch {
    Write-Fail "${Label}: invalid JSON"
    return $false
  }

  if ($obj.chain -ne "base") { Write-Fail "${Label}: chain != base"; return $false }
  if ($obj.summary.action -ne $Action) { Write-Fail "${Label}: action != $Action"; return $false }
  if (-not $obj.calls -or $obj.calls.Count -lt 1) { Write-Fail "${Label}: no calls"; return $false }

  foreach ($call in $obj.calls) {
    if (-not $call.to -or -not $call.data.StartsWith("0x") -or $null -eq $call.value) {
      Write-Fail "${Label}: malformed call entry"
      return $false
    }
  }

  Write-Pass "$Label ($($obj.calls.Count) call(s), action=$Action)"
  return $true
}

function Test-ExpectedError {
  param([string]$Label, [string]$Pattern, [string[]]$CliArgs)
  $r = Invoke-SectorOne @CliArgs
  if ($r.ExitCode -eq 0) {
    Write-Fail "${Label}: expected error matching $Pattern"
    return $false
  }
  if ($r.Output -match $Pattern) {
    Write-Pass "$Label (expected error: $Pattern)"
    return $true
  }
  Write-Fail "${Label}: unexpected error"
  Write-Host ($r.Output | Select-Object -Last 5)
  return $false
}

Write-Host "=== SectorOne Bankr execute dry-run ==="
Write-Host "CLI root: $Root"
Write-Host "RPC: $($env:BASE_RPC_URL)"
Write-Host "Dry wallet: $DryWallet"
if ($LpWallet) { Write-Host "LP wallet: $LpWallet" } else { Write-Host "LP wallet: (not set - partial remove validation)" }
Write-Host ""

Write-Host "--- list-pairs ---"
$list = Invoke-SectorOne list-pairs --token-in $Usdc --token-out $Weth --token-in-decimals 6 --token-out-decimals 18 --lb-version v2 --json
if ($list.ExitCode -eq 0) {
  $listObj = $list.Output | ConvertFrom-Json
  if ($listObj.chainId -eq 8453 -and $listObj.pairs.Count -gt 0) {
    Write-Pass "list-pairs ($($listObj.pairs.Count) pairs)"
  } else {
    Write-Fail "list-pairs: invalid payload"
  }
} else {
  Write-Fail "list-pairs command failed"
}

Write-Host "--- Flow A: build-create-pool ---"
$create = Invoke-SectorOne build-create-pool `
  --token-x $Usdc --token-y $Dai `
  --token-x-decimals 6 --token-y-decimals 18 `
  --bin-step $BinStep --lb-version v2 `
  --price-token-y-per-token-x 1 `
  --confirm-create --json

if ($create.ExitCode -eq 0) {
  [void](Test-BankrPayload "create pool" $create.Output "createLBPair")
} elseif ($create.Output -match "PAIR_ALREADY_EXISTS") {
  Write-Pass "create pool preflight (PAIR_ALREADY_EXISTS - use Flow B instead)"
} else {
  Write-Fail "create pool: unexpected error"
  Write-Host ($create.Output | Select-Object -Last 8)
}

Write-Host "--- Flow B: build-add-liquidity ---"
$add = Invoke-SectorOne build-add-liquidity `
  --wallet $DryWallet `
  --token-x $Usdc --token-y $Weth `
  --token-x-decimals 6 --token-y-decimals 18 `
  --amount-x 1 --amount-y 0.0001 `
  --bin-step $BinStep --lb-version v2 --json

$activeId = $null
$pairAddr = $null
if ($add.ExitCode -eq 0 -and (Test-BankrPayload "add liquidity" $add.Output "addLiquidity")) {
  $addObj = $add.Output | ConvertFrom-Json
  $activeId = $addObj.summary.activeId
  $pairAddr = $addObj.summary.pair
}

Write-Host "--- Flow C: build-remove-liquidity ---"
$binForGuard = if ($activeId) { "$activeId" } else { "8380586" }
[void](Test-ExpectedError "remove mode guard" "REMOVE_MODE_REQUIRED" @(
  "build-remove-liquidity",
  "--wallet", $DryWallet,
  "--token-x", $Usdc, "--token-y", $Weth,
  "--token-x-decimals", "6", "--token-y-decimals", "18",
  "--bin-step", $BinStep, "--bin-ids", $binForGuard
))

if ($LpWallet -and $activeId) {
  $remove = Invoke-SectorOne build-remove-liquidity `
    --wallet $LpWallet `
    --token-x $Usdc --token-y $Weth `
    --token-x-decimals 6 --token-y-decimals 18 `
    --bin-step $BinStep `
    --bin-ids "$activeId" `
    --remove-all --lb-version v2 --json

  if ($remove.ExitCode -eq 0) {
    [void](Test-BankrPayload "remove liquidity (LP wallet)" $remove.Output "removeLiquidity")
  } else {
    Write-Fail "remove liquidity with SECTORONE_DRY_RUN_LP_WALLET"
    Write-Host ($remove.Output | Select-Object -Last 8)
  }
} elseif ($activeId) {
  [void](Test-ExpectedError "remove preflight (no LP)" "NO_LP_IN_BIN" @(
    "build-remove-liquidity",
    "--wallet", $DryWallet,
    "--token-x", $Usdc, "--token-y", $Weth,
    "--token-x-decimals", "6", "--token-y-decimals", "18",
    "--bin-step", $BinStep, "--bin-ids", "$activeId",
    "--remove-all", "--lb-version", "v2", "--json"
  ))
  Write-Skip "remove calldata JSON - set SECTORONE_DRY_RUN_LP_WALLET for full validation"
} else {
  Write-Skip "remove flow - add liquidity step failed"
}

Write-Host ""
Write-Host "=== Summary: $($script:Pass) passed, $($script:Fail) failed, $($script:Skip) skipped ==="
if ($script:Fail -gt 0) { exit 1 }
exit 0
