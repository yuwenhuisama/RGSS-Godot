param([string]$Name = 'd05-original-native-input')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root ('.omo/compatibility-run-tmp/' + $Name)
& ruby (Join-Path $PSScriptRoot 'prepare_original_fixture.rb') (Get-TestPath 'game_project') $work (Join-Path $root 'tests/fixtures/message_original_input_reference.rb') --stock-scripts
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$watch = New-Object System.IO.FileSystemWatcher $work, 'message_input_ready.txt'
$subscription = Register-ObjectEvent $watch Created -SourceIdentifier 'D05InputReady'
$watch.EnableRaisingEvents = $true
$game = Start-Process (Join-Path $work 'Game.exe') -WorkingDirectory $work -PassThru
$null = $game.Handle
try {
if (-not $game.WaitForInputIdle(10000)) { throw 'Original window did not initialize' }
while (-not (Test-Path (Join-Path $work 'message_input_ready.txt'))) {
    if (-not (Wait-Event -SourceIdentifier 'D05InputReady' -Timeout 15)) { throw 'Original input-ready marker missing' }
}
Unregister-Event -SourceIdentifier 'D05InputReady'
Remove-Event -SourceIdentifier 'D05InputReady' -ErrorAction SilentlyContinue
$watch.Dispose()
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class D05ForegroundProbe {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr window, out uint process);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint from, uint to, bool attach);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr window);
}
'@
if (-not (New-Object -ComObject WScript.Shell).AppActivate($game.Id)) { throw 'Cannot activate ready original input window' }
$game.Refresh()
$currentThread = [D05ForegroundProbe]::GetCurrentThreadId()
[uint32]$currentForegroundProcess = 0
$foregroundThread = [D05ForegroundProbe]::GetWindowThreadProcessId([D05ForegroundProbe]::GetForegroundWindow(), [ref]$currentForegroundProcess)
$attached = $false
try {
    if ($foregroundThread -ne $currentThread) { $attached = [D05ForegroundProbe]::AttachThreadInput($currentThread, $foregroundThread, $true) }
    $activated = [D05ForegroundProbe]::SetForegroundWindow($game.MainWindowHandle)
} finally {
    if ($attached) { $null = [D05ForegroundProbe]::AttachThreadInput($currentThread, $foregroundThread, $false) }
}
$foreground = [D05ForegroundProbe]::GetForegroundWindow()
[uint32]$foregroundProcess = 0
$null = [D05ForegroundProbe]::GetWindowThreadProcessId($foreground, [ref]$foregroundProcess)
$game.Refresh()
Write-Output "D05_FOREGROUND_DIAGNOSTIC:expected=$($game.Id):actual=$($foregroundProcess):foreground=$($foreground):main=$($game.MainWindowHandle):activated=$activated"
if ($foregroundProcess -ne $game.Id) { throw 'Ready original did not obtain foreground; no keys sent' }
Set-Content (Join-Path $work 'message_input_activated.txt') 'activated'
$game.WaitForExit()
if ($game.ExitCode -ne 0) { throw "Original exit $($game.ExitCode)" }
if (-not (Test-Path (Join-Path $work 'message_original_input_complete.txt'))) {
    Get-Content (Join-Path $work 'message_original_input_error.txt')
    throw 'Original message input did not complete'
}
Get-Content (Join-Path $work 'message_original_input.tsv')
Get-Content (Join-Path $work 'message_original_input_complete.txt')
} finally {
    Unregister-Event -SourceIdentifier 'D05InputReady' -ErrorAction SilentlyContinue
    Remove-Event -SourceIdentifier 'D05InputReady' -ErrorAction SilentlyContinue
    $watch.Dispose()
    $game.Refresh()
    if (-not $game.HasExited) {
        $game.Kill()
        $game.WaitForExit()
    }
    $game.Dispose()
}
