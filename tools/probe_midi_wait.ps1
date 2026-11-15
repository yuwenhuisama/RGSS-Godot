$ErrorActionPreference='Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class MidiWaitProbe {
 [DllImport("winmm.dll",CharSet=CharSet.Unicode)] static extern uint mciSendStringW(string cmd,StringBuilder result,uint size,IntPtr hwnd);
 public static string Send(string cmd){var result=new StringBuilder(256);var error=mciSendStringW(cmd,result,256,IntPtr.Zero);return cmd+":error="+error+":"+result;}
}
'@
$file=Join-Path (Split-Path -Parent $PSScriptRoot) 'tests/fixtures/midi-reference.mid'
Write-Output ([MidiWaitProbe]::Send("open `"$file`" type sequencer alias midi_wait"))
Write-Output ([MidiWaitProbe]::Send('set midi_wait time format milliseconds'))
Write-Output ([MidiWaitProbe]::Send('play midi_wait wait'))
Write-Output ([MidiWaitProbe]::Send('status midi_wait position'))
Write-Output ([MidiWaitProbe]::Send('close midi_wait'))
