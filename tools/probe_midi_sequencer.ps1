$ErrorActionPreference='Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class MidiProbe {
 [DllImport("winmm.dll",CharSet=CharSet.Unicode)] static extern uint mciSendStringW(string cmd,StringBuilder result,uint size,IntPtr hwnd);
 public static string Send(string cmd){ var b=new StringBuilder(256); var error=mciSendStringW(cmd,b,256,IntPtr.Zero); return cmd+":error="+error+":"+b; }
}
'@
$path=Join-Path (Split-Path -Parent $PSScriptRoot) 'tests/fixtures/midi-reference.mid'
Write-Output ([MidiProbe]::Send("open `"$path`" type sequencer alias midi_probe"))
Write-Output ([MidiProbe]::Send('set midi_probe time format milliseconds'))
Write-Output ([MidiProbe]::Send('status midi_probe length'))
Write-Output ([MidiProbe]::Send('play midi_probe'))
Write-Output ([MidiProbe]::Send('status midi_probe mode'))
Write-Output ([MidiProbe]::Send('status midi_probe position'))
Write-Output ([MidiProbe]::Send('close midi_probe'))
