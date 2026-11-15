param([string]$Device = 'Voicemeeter Out B2 (VB-Audio Voicemeeter VAIO)', [string]$Name = 'e07-route-b2-control')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root ('.omo/compatibility-run-tmp/' + $Name)
if (Test-Path $work) { throw 'Control directory already exists' }
New-Item -ItemType Directory -Path $work | Out-Null
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class AudioRouteControl {
 [DllImport("winmm.dll", CharSet=CharSet.Unicode)]
 public static extern bool PlaySound(string filename, IntPtr module, uint flags);
}
'@
$args = '-hide_banner -loglevel info -thread_queue_size 512 -f dshow -i "audio=' + $Device + '" -t 4 -ac 2 -ar 48000 -y "' + (Join-Path $work 'control.wav') + '"'
$recording = Start-Process 'F:/Softwares/oopz/ffmpeg.exe' -ArgumentList $args -RedirectStandardError (Join-Path $work 'capture.log') -PassThru -NoNewWindow
$null = $recording.Handle
$tone = Join-Path $root 'tests/fixtures/audio/tone.wav'
for ($i = 0; $i -lt 5; $i++) {
 if (-not [AudioRouteControl]::PlaySound($tone, [IntPtr]::Zero, 0x20000)) { throw 'Control tone playback failed' }
}
$recording.WaitForExit()
Write-Output "AUDIO_ROUTE_CAPTURE_EXIT:$($recording.ExitCode)"
exit $recording.ExitCode
