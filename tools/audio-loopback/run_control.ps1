param([string]$Name = 'e07-wasapi-control', [string]$DeviceId = '')
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$work = Join-Path $root ('.omo/compatibility-run-tmp/' + $Name)
if (Test-Path $work) { throw 'Control directory already exists' }
New-Item -ItemType Directory -Path $work | Out-Null
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class WasapiControlTone {
 [DllImport("winmm.dll", CharSet=CharSet.Unicode)]
 public static extern bool PlaySound(string filename, IntPtr module, uint flags);
}
'@
$exe = Join-Path $PSScriptRoot 'bin/Release/net8.0-windows/AudioLoopback.exe'
$captureArgs = @((Join-Path $work 'control.wav'), '5')
if ($DeviceId) { $captureArgs += $DeviceId }
$capture = Start-Process $exe -ArgumentList $captureArgs -RedirectStandardOutput (Join-Path $work 'capture.log') -RedirectStandardError (Join-Path $work 'capture-error.log') -PassThru -NoNewWindow
$null = $capture.Handle
for ($index = 0; $index -lt 8; $index++) {
 if (-not [WasapiControlTone]::PlaySound((Join-Path $root 'tests/fixtures/audio/tone.wav'), [IntPtr]::Zero, 0x20000)) { throw 'Control tone failed' }
}
$capture.WaitForExit()
Get-Content (Join-Path $work 'capture.log')
Write-Output "WASAPI_CONTROL_EXIT:$($capture.ExitCode)"
exit $capture.ExitCode
