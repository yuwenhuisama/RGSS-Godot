param([string]$FixtureName = 'zlib-stream-original')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$destination = Join-Path $root ('.omo/compatibility-run-tmp/' + $FixtureName)
& ruby (Join-Path $PSScriptRoot 'prepare_original_fixture.rb') (Get-TestPath 'game_project') $destination (Join-Path $root 'tests/fixtures/zlib_stream_reference.rb')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$process = Start-Process (Join-Path $destination 'Game.exe') -WorkingDirectory $destination -PassThru -Wait
if ($process.ExitCode -ne 0) { exit $process.ExitCode }
$result = Join-Path $destination 'zlib_stream_reference.tsv'
if (-not (Test-Path $result)) { throw 'Original stream result missing' }
Get-Content $result
Copy-Item $result (Join-Path $root 'tests/fixtures/zlib_stream_original.tsv')
Write-Output 'ORIGINAL_ZLIB_STREAM_CAPTURED'
