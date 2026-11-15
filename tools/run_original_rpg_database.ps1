$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/f01-rpg-database-original')
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (-not (Test-Path './rpg_database_reference.tsv')) { throw 'Database ledger missing' }
Write-Output 'ORIGINAL_RPG_DATABASE_READY'
