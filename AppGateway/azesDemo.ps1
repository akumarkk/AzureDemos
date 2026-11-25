# Dot-source:  . C:\Users\devAdmin\anikris\azeDemos\AppGateway\azedemo.ps1   then run Get-DemoHelp
# Reproduces the "existing blocks shown as - and +" plan noise on a minimal Application Gateway.

$Demo = @{
    Dir  = $PSScriptRoot
    Logs = Join-Path $PSScriptRoot 'logs'
}
New-Item -ItemType Directory -Force $Demo.Logs | Out-Null

function Invoke-DemoTf {
    param([string]$Name, [string[]]$TfArgs, [int[]]$OkCodes = @(0))
    $log = Join-Path $Demo.Logs ('{0}-{1:yyyyMMdd-HHmmss}.log' -f $Name, (Get-Date))
    Write-Host "> terraform $($TfArgs -join ' ')" -ForegroundColor DarkGray
    Push-Location $Demo.Dir
    try {
        & terraform @TfArgs 2>&1 | ForEach-Object { "$_" } | Tee-Object -FilePath $log
        $script:TfRc = $LASTEXITCODE
    }
    finally { Pop-Location }
    Write-Host "Log: $log"
    if ($OkCodes -notcontains $script:TfRc) { throw "terraform exited with $script:TfRc" }
}

function Get-DemoHelp {
    @'
Order:
  1. Initialize-Demo        terraform init + validate (no Azure resources)
  2. Deploy-Base            apply base.tfvars (apps alpha, beta) - takes ~5-15 min
  3. Test-BaseClean         plan base.tfvars, expect "No changes"
  4. Get-AddPlan            plan add.tfvars (adds gamma), save plan.txt/plan.json, compare
     Get-AddPlan -ExplicitEmpty   same, with optional text fields set to "" (probes/settings become clean)
  5. Compare-DemoPlan       re-run the comparison on the last plan
  6. Remove-Demo            destroy everything (asks first)
'@ | Write-Host
}

function Initialize-Demo {
    try {
        Invoke-DemoTf 'init' @('init', '-input=false', '-no-color')
        Invoke-DemoTf 'validate' @('validate', '-no-color')
    }
    catch { Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red }
}

function Deploy-Base {
    try {
        Invoke-DemoTf 'apply-base' @('apply', '-auto-approve', '-input=false', '-no-color', '-var-file=base.tfvars')
        Write-Host 'Base deployed' -ForegroundColor Green
    }
    catch { Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red }
}

function Test-BaseClean {
    try {
        Invoke-DemoTf 'plan-base' @('plan', '-input=false', '-no-color', '-detailed-exitcode', '-var-file=base.tfvars') -OkCodes 0, 2
        if ($script:TfRc -eq 0) { Write-Host 'CLEAN: no changes' -ForegroundColor Green }
        else { Write-Host 'NOT CLEAN: see log' -ForegroundColor Yellow }
    }
    catch { Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red }
}

function Get-AddPlan {
    param([switch]$ExplicitEmpty)
    try {
        $a = @('plan', '-input=false', '-no-color', '-var-file=add.tfvars', '-out=tfplan')
        if ($ExplicitEmpty) { $a += '-var=explicit_empty=true' }
        Invoke-DemoTf 'plan-add' $a
        Push-Location $Demo.Dir
        try {
            terraform show -no-color tfplan | Out-File plan.txt -Encoding utf8
            terraform show -json tfplan | Out-File plan.json -Encoding utf8
        }
        finally { Pop-Location }
        Compare-DemoPlan
    }
    catch { Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red }
}

# Null and "" are treated as equal; arrays of strings are sorted.
function ConvertTo-DemoNorm {
    param($Value)
    if ($null -eq $Value) { return '' }
    if ($Value -is [string]) { return $Value }
    if ($Value -is [System.Array]) {
        $items = @($Value | ForEach-Object { ConvertTo-DemoNorm $_ })
        if ($items.Count -gt 0 -and $items[0] -is [string]) { $items = @($items | Sort-Object) }
        return , $items
    }
    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        $h = [ordered]@{}
        foreach ($p in $Value.PSObject.Properties) { $h[$p.Name] = ConvertTo-DemoNorm $p.Value }
        return $h
    }
    return $Value
}

function Compare-DemoSet {
    param([string]$Label, $Before, $After)
    $b = @($Before | Where-Object { $_ })
    $a = @($After | Where-Object { $_ })
    $bn = @($b | ForEach-Object { $_.name })
    $an = @($a | ForEach-Object { $_.name })
    Write-Host "== $Label  before=$($bn.Count) after=$($an.Count)"
    foreach ($n in ($bn | Where-Object { $_ -notin $an })) { Write-Host "  REMOVED: $n" -ForegroundColor Red }
    foreach ($n in ($an | Where-Object { $_ -notin $bn })) { Write-Host "  ADDED:   $n" -ForegroundColor Green }
    foreach ($n in ($bn | Where-Object { $_ -in $an })) {
        $x = $b | Where-Object { $_.name -eq $n } | Select-Object -First 1
        $y = $a | Where-Object { $_.name -eq $n } | Select-Object -First 1
        $props = @($x.PSObject.Properties.Name) + @($y.PSObject.Properties.Name) | Select-Object -Unique
        $diffs = foreach ($p in $props) {
            if ($p -eq 'id' -or $p -like '*_id') { continue }
            $jx = ConvertTo-Json -InputObject (ConvertTo-DemoNorm $x.$p) -Depth 10 -Compress
            $jy = ConvertTo-Json -InputObject (ConvertTo-DemoNorm $y.$p) -Depth 10 -Compress
            if ($jx -ne $jy) { "    $p : before=$jx  after=$jy" }
        }
        if ($diffs) { Write-Host "  CHANGED: $n" -ForegroundColor Yellow; $diffs | ForEach-Object { Write-Host $_ } }
    }
}

function Compare-DemoPlan {
    $json = Join-Path $Demo.Dir 'plan.json'
    $txt = Join-Path $Demo.Dir 'plan.txt'
    if (-not (Test-Path $json)) { Write-Host 'No plan.json, run Get-AddPlan first' -ForegroundColor Yellow; return }

    $p = Get-Content $json -Raw | ConvertFrom-Json
    $rc = $p.resource_changes | Where-Object { $_.address -eq 'azurerm_application_gateway.demo' }
    if (-not $rc) { Write-Host 'application gateway not in plan'; return }
    Write-Host "gateway actions: $($rc.change.actions -join ',')"

    $types = 'http_listener', 'backend_address_pool', 'backend_http_settings', 'probe', 'request_routing_rule'

    Write-Host "`n--- Semantic comparison (null and empty string treated as equal) ---"
    foreach ($t in $types) { Compare-DemoSet $t $rc.change.before.$t $rc.change.after.$t }

    Write-Host "`n--- What the text plan shows (blocks marked - and +) ---"
    '{0,-24} {1,8} {2,8}' -f 'block', 'minus', 'plus' | Write-Host
    foreach ($t in $types) {
        $m = @(Select-String -Path $txt -Pattern "^\s+- $t \{").Count
        $pl = @(Select-String -Path $txt -Pattern "^\s+\+ $t \{").Count
        '{0,-24} {1,8} {2,8}' -f $t, $m, $pl | Write-Host
    }
    Write-Host 'A non-zero minus count means existing items are displayed as removed and re-added.'
}

function Remove-Demo {
    try {
        $ans = Read-Host 'Destroy the demo resource group and everything in it? (yes/no)'
        if ($ans -ne 'yes') { Write-Host 'aborted'; return }
        Invoke-DemoTf 'destroy' @('destroy', '-auto-approve', '-input=false', '-no-color', '-var-file=base.tfvars')
    }
    catch { Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red }
}