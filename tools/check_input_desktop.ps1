param([switch]$WaitForDefault)
$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class RGSSInputDesktop {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern IntPtr OpenInputDesktop(uint flags, bool inherit, uint access);
    [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern bool GetUserObjectInformation(IntPtr handle, int index, StringBuilder name, uint size, out uint needed);
    [DllImport("user32.dll")]
    public static extern bool CloseDesktop(IntPtr handle);
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr handle, out uint process);
}
'@
do {
    $name = ''
    $handle = [RGSSInputDesktop]::OpenInputDesktop(0, $false, 1)
    if ($handle -ne [IntPtr]::Zero) {
        try {
            $buffer = New-Object System.Text.StringBuilder 256
            [uint32]$needed = 0
            if (-not [RGSSInputDesktop]::GetUserObjectInformation($handle, 2, $buffer, 512, [ref]$needed)) {
                throw "Input desktop name query failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
            }
            $name = $buffer.ToString()
        } finally { $null = [RGSSInputDesktop]::CloseDesktop($handle) }
    } elseif (-not $WaitForDefault) {
        throw "Input desktop open failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    }
    [uint32]$foregroundId = 0
    $window = [RGSSInputDesktop]::GetForegroundWindow()
    $null = [RGSSInputDesktop]::GetWindowThreadProcessId($window, [ref]$foregroundId)
    $foreground = Get-Process -Id $foregroundId -ErrorAction SilentlyContinue
    $interactive = $window -ne [IntPtr]::Zero -and $null -ne $foreground -and $foreground.ProcessName -notin @('LockApp', 'LogonUI')
    if ($name -eq 'Default' -and $interactive) {
        Write-Output 'INPUT_DESKTOP_READY:Default'
        exit 0
    }
    if (-not $WaitForDefault) { throw "Input desktop unavailable: name=$name foreground=$($foreground.ProcessName) pid=$foregroundId" }
    Start-Sleep -Seconds 5
} while ($true)
