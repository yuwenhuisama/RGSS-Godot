param([string]$Name = 'f08-zlib-family-original', [string]$Fixture = 'zlib_family_reference.rb', [string]$Ledger = 'zlib_family_reference.tsv')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root ('.omo/compatibility-run-tmp/' + $Name)
& ruby (Join-Path $PSScriptRoot 'prepare_original_fixture.rb') 'E:/Projects/RMProject' $work (Join-Path $root ('tests/fixtures/' + $Fixture))
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$game = Start-Process (Join-Path $work 'Game.exe') -WorkingDirectory $work -PassThru
$null = $game.Handle
if (-not $game.WaitForExit(30000)) {
    Stop-Process -Id $game.Id
    throw "Original fixture exceeded 30 seconds: $work"
}
if ($game.ExitCode -ne 0) { throw "Original exit $($game.ExitCode)" }
Get-Content (Join-Path $work $Ledger)
Write-Output 'ORIGINAL_ZLIB_FAMILY_CAPTURED'
