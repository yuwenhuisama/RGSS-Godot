$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '../.omo/compatibility-run-tmp/f03-default-order-original')
$process = Start-Process ./Game.exe -PassThru -Wait
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { exit 1 }
if (-not (Test-Path './default_draw_order_reference.tsv')) { throw 'Default order ledger missing' }
Write-Output 'ORIGINAL_DEFAULT_ORDER_READY'
