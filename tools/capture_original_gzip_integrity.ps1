param([string]$Name = 'f08-gzip-integrity', [string]$Case = '', [int]$ExpectedRows = 6)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root ('.omo/compatibility-run-tmp/' + $Name)
& ruby (Join-Path $PSScriptRoot 'prepare_original_fixture.rb') 'E:/Projects/RMProject' $work (Join-Path $root 'tests/fixtures/gzip_integrity_reference.rb')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if ($Case) { [System.IO.File]::WriteAllText((Join-Path $work 'gzip_integrity_case.txt'), $Case) }
$game = Start-Process (Join-Path $work 'Game.exe') -WorkingDirectory $work -PassThru
$null = $game.Handle
try {
    if (-not $game.WaitForExit(30000)) {
        $fatal = Join-Path $work 'gzip_integrity_fatal.txt'
        if (Test-Path $fatal) { Get-Content $fatal }
        throw 'Original Gzip integrity probe timed out'
    }
    if ($game.ExitCode -ne 0) { throw "Original exit $($game.ExitCode)" }
    $rows = Get-Content (Join-Path $work 'gzip_integrity.tsv')
    if ($rows.Count -ne $ExpectedRows) { throw 'Original Gzip integrity probe incomplete' }
    $rows
    Write-Output "ORIGINAL_GZIP_INTEGRITY_PASS:$ExpectedRows"
} finally {
    if (-not $game.HasExited) { $game.Kill(); $game.WaitForExit() }
    $game.Dispose()
}
