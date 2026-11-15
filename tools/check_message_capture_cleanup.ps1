$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$tokens = $null
$errors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'capture_original_message_input.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count -ne 0) { throw ($errors | Out-String) }
$prior = Get-Process -Id 270808 -ErrorAction SilentlyContinue
if ($prior -and $prior.Path -eq (Join-Path $root '.omo/compatibility-run-tmp/d05-original-input-final-check/Game.exe')) {
    $prior.Kill()
    $prior.WaitForExit()
}
$target = Join-Path $root '.omo/compatibility-run-tmp/d05-original-input-cleanup-check/Game.exe'
$remaining = @(Get-CimInstance Win32_Process -Filter "Name='Game.exe'" | Where-Object ExecutablePath -eq $target)
if ($remaining.Count -ne 0) { throw 'Failed capture left its owned Game.exe alive' }
Write-Output 'D05_CAPTURE_CLEANUP_PASS'
