param([string]$FixtureName = 'e07-wasapi-midi-me-original', [switch]$InspectSessions, [string]$DeviceId = '', [switch]$Activate, [string]$FixtureScript = 'tests/fixtures/midi_me_signal_reference.rb')
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$work = Join-Path $root ('.omo/compatibility-run-tmp/' + $FixtureName)
& ruby (Join-Path $root 'tools/prepare_original_fixture.rb') 'E:/Projects/RMProject' $work (Join-Path $root $FixtureScript)
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$exe = Join-Path $PSScriptRoot 'bin/Release/net8.0-windows/AudioLoopback.exe'
$captureArgs = @((Join-Path $work 'capture.wav'), '16')
if ($DeviceId) { $captureArgs += $DeviceId }
$capture = Start-Process $exe -ArgumentList $captureArgs -RedirectStandardOutput (Join-Path $work 'capture.log') -RedirectStandardError (Join-Path $work 'capture-error.log') -PassThru -NoNewWindow
$null = $capture.Handle
$watch = New-Object System.IO.FileSystemWatcher $work, 'midi_me_signal_events.tsv'
$game = Start-Process (Join-Path $work 'Game.exe') -WorkingDirectory $work -PassThru
$null = $game.Handle
if ($Activate) {
    if (-not $game.WaitForInputIdle(10000)) { throw 'Original window did not initialize' }
    $activated = (New-Object -ComObject WScript.Shell).AppActivate($game.Id)
    Write-Output "ORIGINAL_WINDOW_ACTIVATED:$activated"
}
if ($InspectSessions) {
    $events = Join-Path $work 'midi_me_signal_events.tsv'
    while (-not ((Test-Path $events) -and (Select-String -Path $events -Pattern 'midi-start' -Quiet))) {
        $change = $watch.WaitForChanged([System.IO.WatcherChangeTypes]::All, 15000)
        if ($change.TimedOut) { throw 'MIDI-start marker did not arrive' }
    }
    Write-Output "ORIGINAL_MIDI_PID:$($game.Id)"
    & $exe --devices
}
$watch.Dispose()
$game.WaitForExit()
$capture.WaitForExit()
if ($game.ExitCode -ne 0 -or $capture.ExitCode -ne 0) { throw "Original=$($game.ExitCode), Capture=$($capture.ExitCode)" }
Get-Content (Join-Path $work 'capture.log')
Get-Content (Join-Path $work 'midi_me_signal_events.tsv')
Write-Output 'ORIGINAL_WASAPI_MIDI_ME_CAPTURED'
