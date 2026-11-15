param([string]$FixtureName = 'e07-midi-me-signal-original', [string]$Device = 'Voicemeeter Out B1 (VB-Audio Voicemeeter VAIO)')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root ('.omo/compatibility-run-tmp/' + $FixtureName)
& ruby (Join-Path $PSScriptRoot 'prepare_original_fixture.rb') 'E:/Projects/RMProject' $work (Join-Path $root 'tests/fixtures/midi_me_signal_reference.rb')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$capture = Join-Path $work 'midi-me-capture.wav'
$log = Join-Path $work 'capture-stderr.log'
$arguments = '-hide_banner -loglevel info -thread_queue_size 512 -f dshow -audio_buffer_size 50 -i "audio=' + $Device + '" -t 16 -ac 2 -ar 48000 -y "' + $capture + '"'
$started = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() / 1000.0
$recording = Start-Process 'F:/Softwares/oopz/ffmpeg.exe' -ArgumentList $arguments -RedirectStandardError $log -RedirectStandardOutput (Join-Path $work 'capture-stdout.log') -PassThru -NoNewWindow
$null = $recording.Handle
$game = Start-Process (Join-Path $work 'Game.exe') -WorkingDirectory $work -PassThru -Wait
$recording.WaitForExit()
$recording.Refresh()
$game.Refresh()
if ($recording.ExitCode -ne 0) { throw "Capture exit $($recording.ExitCode); HasExited=$($recording.HasExited)" }
if ($game.ExitCode -ne 0) { throw "Original exit $($game.ExitCode)" }
Set-Content (Join-Path $work 'capture-start.txt') $started
Get-Content (Join-Path $work 'midi_me_signal_events.tsv')
Write-Output 'ORIGINAL_MIDI_ME_SIGNAL_CAPTURED'
