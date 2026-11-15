param([string]$Name = 'f08-gzip-extended-encoding', [int]$ExpectedRows = 14)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root ('.omo/compatibility-run-tmp/' + $Name)
& ruby (Join-Path $PSScriptRoot 'prepare_original_fixture.rb') 'E:/Projects/RMProject' $work (Join-Path $root 'tests/fixtures/gzip_encoding_extended_reference.rb')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$game = Start-Process (Join-Path $work 'Game.exe') -WorkingDirectory $work -PassThru
$null = $game.Handle
try {
    if (-not $game.WaitForExit(30000)) { throw 'Original Gzip encoding probe timed out' }
    if ($game.ExitCode -ne 0) { throw "Original exit $($game.ExitCode)" }
    $rows = Get-Content (Join-Path $work 'gzip_encoding_extended.tsv')
    if ($rows.Count -ne $ExpectedRows) { throw 'Original Gzip encoding probe incomplete' }
    $rows
    Write-Output "ORIGINAL_GZIP_EXTENDED_PASS:$ExpectedRows"
} finally {
    if (-not $game.HasExited) { $game.Kill(); $game.WaitForExit() }
    $game.Dispose()
}
