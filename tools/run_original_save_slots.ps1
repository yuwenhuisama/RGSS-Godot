$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/test_paths.ps1"
$destination = Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/f03-save-slots-original'
Get-ChildItem (Join-Path (Get-TestPath 'game_project') 'Data/*.rvdata2') | Where-Object Name -ne 'Scripts.rvdata2' | Copy-Item -Destination (Join-Path $destination 'Data')
Set-Location $destination
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (-not (Test-Path './save_slots_reference.tsv')) { throw 'Save slots ledger missing' }
Write-Output 'ORIGINAL_SAVE_SLOTS_READY'
