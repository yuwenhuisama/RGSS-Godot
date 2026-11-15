$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root '.omo/evidence/c12-runner-lifetime-60hz'
if (Test-Path $work) { throw 'Evidence already exists' }
New-Item -ItemType Directory -Path $work | Out-Null
$process = Start-Process (Get-TestPath 'godot') -ArgumentList @('--windowed', '--path', $root, '-s', 'tests/test_original_fullscreen.gd', '--', '--interactive', '--control-dir', $work, '--logical-size', '544x416') -WorkingDirectory $root -RedirectStandardOutput (Join-Path $work 'stdout.log') -RedirectStandardError (Join-Path $work 'stderr.log') -PassThru
$null = $process.Handle
try {
    if ($process.WaitForExit(90000)) { throw "Runner exited before lifetime boundary: $($process.ExitCode)" }
    if (-not (Test-Path (Join-Path $work 'ready.txt'))) { throw 'Runner never became ready' }
    Set-Content (Join-Path $work 'stop.signal') 'stop'
    if (-not $process.WaitForExit(15000)) { throw 'Runner did not stop cooperatively' }
    if ($process.ExitCode -ne 0) { throw "Runner exit $($process.ExitCode)" }
    Write-Output 'C12_WINDOWED_RUNNER_LIFETIME_PASS:90s'
} finally {
    if (-not $process.HasExited) { $process.Kill(); $process.WaitForExit() }
    $process.Dispose()
}
