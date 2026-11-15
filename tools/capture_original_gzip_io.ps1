param([string]$Name = 'f08-gzip-reader-io', [int]$ExpectedRows = 11)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root ('.omo/compatibility-run-tmp/' + $Name)
& ruby (Join-Path $PSScriptRoot 'prepare_original_fixture.rb') (Get-TestPath 'game_project') $work (Join-Path $root 'tests/fixtures/gzip_reader_io_reference.rb')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$game = Start-Process (Join-Path $work 'Game.exe') -WorkingDirectory $work -PassThru
$null = $game.Handle
try {
    if (-not $game.WaitForExit(30000)) { throw 'Original Gzip IO probe timed out' }
    if ($game.ExitCode -ne 0) { throw "Original exit $($game.ExitCode)" }
    $rows = Get-Content (Join-Path $work 'gzip_reader_io.tsv')
    if ($rows.Count -ne $ExpectedRows) { throw 'Original Gzip IO probe incomplete' }
    $rows
    Write-Output "ORIGINAL_GZIP_IO_PASS:$ExpectedRows"
} finally {
    if (-not $game.HasExited) { $game.Kill(); $game.WaitForExit() }
    $game.Dispose()
}
