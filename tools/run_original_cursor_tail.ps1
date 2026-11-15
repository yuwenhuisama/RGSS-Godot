$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$destination = Join-Path $root '.omo/compatibility-run-tmp/cursor-tail-original'
& ruby (Join-Path $PSScriptRoot 'prepare_original_fixture.rb') (Get-TestPath 'game_project') $destination (Join-Path $root 'tests/fixtures/cursor_tail_reference.rb')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$process = Start-Process (Join-Path $destination 'Game.exe') -WorkingDirectory $destination -PassThru -Wait
if ($process.ExitCode -ne 0) { exit $process.ExitCode }
$result = Join-Path $destination 'cursor_tail_reference.tsv'
if (-not (Test-Path $result)) { throw 'Original cursor tail output missing' }
Copy-Item $result (Join-Path $root 'tests/fixtures/cursor_tail_original.tsv')
Write-Output 'ORIGINAL_CURSOR_TAIL_CAPTURED'
