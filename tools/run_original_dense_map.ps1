# D09 original RGSS300 dense-map capture.
#
# Creates an isolated fixture project under .omo/compatibility-run-tmp/d09-dense-map-original
# from the installed game, replaces Scripts.rvdata2 with the shared fixture, runs
# Game.exe once, and copies the produced TSV to tests/fixtures/dense_map_original.tsv.
# The user's game Data directory is never written.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$source = 'E:/Projects/RMProject'
$destination = Join-Path $root '.omo/compatibility-run-tmp/d09-dense-map-original'
$fixture = Join-Path $root 'tests/fixtures/dense_map_reference.rb'
$capture = Join-Path $destination 'dense_map_reference.tsv'
$target = Join-Path $root 'tests/fixtures/dense_map_original.tsv'

if (Test-Path $destination) { Remove-Item -Recurse -Force $destination }
& ruby (Join-Path $root 'tools/prepare_original_fixture.rb') $source $destination $fixture --stock-scripts
if ($LASTEXITCODE -ne 0) { throw 'Could not prepare the original dense-map fixture' }

# The fixture writes into the working directory, which is the owned fixture root.
Push-Location $destination
try {
    $process = Start-Process ./Game.exe -PassThru -Wait
} finally {
    Pop-Location
}
Write-Output "ORIGINAL_EXIT:$($process.ExitCode)"
if ($process.ExitCode -ne 0) { throw 'Original dense-map fixture exited non-zero' }
if (-not (Test-Path $capture)) { throw 'Original dense-map fixture produced no TSV' }

Copy-Item $capture $target -Force
$rows = (Get-Content $target | Measure-Object -Line).Lines
Write-Output "ORIGINAL_DENSE_MAP_READY:$target rows=$rows"
