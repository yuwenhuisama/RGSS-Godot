param(
    [string]$GodotPath = $(if ($env:GODOT_PATH) { $env:GODOT_PATH } else { 'E:\Godot\Godot_v4.6.1-stable_mono_win64.exe' }),
    [string]$ProjectRoot = 'E:\Projects\RGSS-Godot',
    [string]$EvidenceDir = 'E:\Projects\RGSS-Godot\.omo\evidence\c12-host-fullscreen',
    [string]$TempDir = 'E:\Projects\RGSS-Godot\.omo\compatibility-run-tmp\c12-host-fullscreen',
    [switch]$SkipLegacyRed,
    [switch]$FocusOnly,
    [switch]$F1Entry,
    [int]$AlternateRefreshRate = 0,
    [switch]$NonRegistryOnly
)

$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'check_input_desktop.ps1')
Add-Type -AssemblyName System.Drawing

New-Item -ItemType Directory -Force -Path $EvidenceDir | Out-Null
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
$LogPath = Join-Path $EvidenceDir 'verification.log'
Remove-Item -LiteralPath $LogPath -ErrorAction SilentlyContinue

function Write-Log([string]$Message) {
    $line = (Get-Date -Format 'HH:mm:ss.fff') + ' ' + $Message
    [Console]::WriteLine($line)
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

Add-Type -ReferencedAssemblies System.Drawing @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Text;

public static class C12HostWin32 {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X, Y; }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DEVMODEW {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
        public ushort dmSpecVersion, dmDriverVersion, dmSize, dmDriverExtra;
        public uint dmFields;
        public int dmPositionX, dmPositionY;
        public uint dmDisplayOrientation, dmDisplayFixedOutput;
        public short dmColor, dmDuplex, dmYResolution, dmTTOption, dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
        public ushort dmLogPixels;
        public uint dmBitsPerPel, dmPelsWidth, dmPelsHeight, dmDisplayFlags, dmDisplayFrequency;
        public uint dmICMMethod, dmICMIntent, dmMediaType, dmDitherType, dmReserved1, dmReserved2, dmPanningWidth, dmPanningHeight;
    }

    public delegate bool EnumWindowsProc(IntPtr hwnd, IntPtr lParam);

    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, IntPtr pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hwnd);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr hwnd, StringBuilder sb, int maxCount);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hwnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hwnd, ref POINT pt);
    [DllImport("user32.dll")] public static extern IntPtr GetWindowLongPtrW(IntPtr hwnd, int nIndex);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool EnumDisplaySettingsW(string deviceName, int modeNum, ref DEVMODEW devMode);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int ChangeDisplaySettingsExW(string deviceName, ref DEVMODEW devMode, IntPtr hwnd, uint flags, IntPtr lParam);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int ChangeDisplaySettingsExW(string deviceName, IntPtr devMode, IntPtr hwnd, uint flags, IntPtr lParam);
    [DllImport("shcore.dll")] public static extern int SetProcessDpiAwareness(int value);
    [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr dpiContext);
    [DllImport("gdi32.dll")] public static extern bool BitBlt(IntPtr hdcDest, int xDest, int yDest, int w, int h, IntPtr hdcSrc, int xSrc, int ySrc, int rop);
    [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);

    public static void EnablePhysicalDpiContext() {
        try { SetThreadDpiAwarenessContext(new IntPtr(-4)); } catch { }
    }

    public static DEVMODEW GetCurrentMode() {
        var dm = new DEVMODEW();
        dm.dmSize = (ushort)Marshal.SizeOf(typeof(DEVMODEW));
        if (!EnumDisplaySettingsW(null, -1, ref dm))
            throw new InvalidOperationException("EnumDisplaySettingsW(ENUM_CURRENT_SETTINGS) failed.");
        return dm;
    }

    public static DEVMODEW GetRegistryMode() {
        var dm = new DEVMODEW();
        dm.dmSize = (ushort)Marshal.SizeOf(typeof(DEVMODEW));
        if (!EnumDisplaySettingsW(null, -2, ref dm))
            throw new InvalidOperationException("EnumDisplaySettingsW(ENUM_REGISTRY_SETTINGS) failed.");
        return dm;
    }

    public static string FormatMode(DEVMODEW dm) {
        return string.Format("{0}x{1}@{2}Hz:{3}bpp", dm.dmPelsWidth, dm.dmPelsHeight, dm.dmDisplayFrequency, dm.dmBitsPerPel);
    }

    public static int ApplyDynamicMode(DEVMODEW dm) {
        dm.dmSize = (ushort)Marshal.SizeOf(typeof(DEVMODEW));
        return ChangeDisplaySettingsExW(null, ref dm, IntPtr.Zero, 0, IntPtr.Zero);
    }

    public static bool TryFindNonRegistryMode(DEVMODEW registryMode, int requestedRefresh, out DEVMODEW candidateOut) {
        candidateOut = default(DEVMODEW);
        var m = new DEVMODEW();
        m.dmSize = (ushort)Marshal.SizeOf(typeof(DEVMODEW));
        int idx = 0;
        while (EnumDisplaySettingsW(null, idx++, ref m)) {
            if (m.dmPelsWidth == registryMode.dmPelsWidth
                && m.dmPelsHeight == registryMode.dmPelsHeight
                && m.dmBitsPerPel == registryMode.dmBitsPerPel
                && m.dmDisplayFrequency != registryMode.dmDisplayFrequency
                && (requestedRefresh == 0 || m.dmDisplayFrequency == requestedRefresh)
                && m.dmDisplayFixedOutput == registryMode.dmDisplayFixedOutput) {
                var test = m;
                test.dmSize = (ushort)Marshal.SizeOf(typeof(DEVMODEW));
                if (ChangeDisplaySettingsExW(null, ref test, IntPtr.Zero, 2, IntPtr.Zero) == 0) {
                    candidateOut = m;
                    return true;
                }
            }
        }
        return false;
    }

    public static int ForceRestoreMode(DEVMODEW baseline) {
        int rc = ApplyDynamicMode(baseline);
        if (rc != 0)
            rc = ChangeDisplaySettingsExW(null, IntPtr.Zero, IntPtr.Zero, 0, IntPtr.Zero);
        return rc;
    }

    public static IntPtr FindProcessWindow(uint pid) {
        IntPtr found = IntPtr.Zero;
        EnumWindows((IntPtr h, IntPtr d) => {
            uint owner;
            GetWindowThreadProcessId(h, out owner);
            if (owner == pid && IsWindowVisible(h)) {
                var sb = new StringBuilder(256);
                GetWindowTextW(h, sb, 256);
                if (sb.Length > 0) {
                    found = h;
                    return false;
                }
            }
            return true;
        }, IntPtr.Zero);
        return found;
    }

    public static bool EnsureForeground(IntPtr hwnd) {
        for (int i = 0; i < 20; i++) {
            if (GetForegroundWindow() == hwnd) return true;
            IntPtr fg = GetForegroundWindow();
            uint cur = GetCurrentThreadId();
            uint fgThread = fg != IntPtr.Zero ? GetWindowThreadProcessId(fg, IntPtr.Zero) : 0;
            if (fgThread != 0 && fgThread != cur) AttachThreadInput(cur, fgThread, true);
            keybd_event(0x12, 0, 0, UIntPtr.Zero);
            keybd_event(0x12, 0, 2, UIntPtr.Zero);
            BringWindowToTop(hwnd);
            SetForegroundWindow(hwnd);
            if (fgThread != 0 && fgThread != cur) AttachThreadInput(cur, fgThread, false);
            System.Threading.Thread.Sleep(100);
        }
        return GetForegroundWindow() == hwnd;
    }

    public static string DescribeWindow(IntPtr hwnd) {
        if (hwnd == IntPtr.Zero || !IsWindow(hwnd)) return "invalid";
        RECT client, window;
        GetClientRect(hwnd, out client);
        GetWindowRect(hwnd, out window);
        var origin = new POINT();
        ClientToScreen(hwnd, ref origin);
        long style = GetWindowLongPtrW(hwnd, -16).ToInt64();
        long ex = GetWindowLongPtrW(hwnd, -20).ToInt64();
        return string.Format("client={0}x{1}|origin={2},{3}|window={4},{5},{6},{7}|style=0x{8:X}|ex=0x{9:X}|fg={10}",
            client.Right, client.Bottom, origin.X, origin.Y, window.Left, window.Top, window.Right, window.Bottom, style, ex, GetForegroundWindow() == hwnd);
    }

    public static Bitmap CaptureDesktop(int width, int height) {
        EnablePhysicalDpiContext();
        var bmp = new Bitmap(width, height, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp)) {
            IntPtr hdcDest = g.GetHdc();
            IntPtr hdcSrc = GetDC(IntPtr.Zero);
            try {
                if (!BitBlt(hdcDest, 0, 0, width, height, hdcSrc, 0, 0, 0x00CC0020))
                    throw new InvalidOperationException("BitBlt from desktop DC failed.");
            } finally {
                ReleaseDC(IntPtr.Zero, hdcSrc);
                g.ReleaseHdc(hdcDest);
            }
        }
        return bmp;
    }
}
'@

[C12HostWin32]::EnablePhysicalDpiContext()

$BaselineCurrent = [C12HostWin32]::GetCurrentMode()
$BaselineRegistry = [C12HostWin32]::GetRegistryMode()
$BaselineCurrentStr = [C12HostWin32]::FormatMode($BaselineCurrent)
$BaselineRegistryStr = [C12HostWin32]::FormatMode($BaselineRegistry)
Write-Log "BASELINE_CURRENT:$BaselineCurrentStr"
Write-Log "BASELINE_REGISTRY:$BaselineRegistryStr"

function Test-PixelExact([System.Drawing.Bitmap]$Bmp, [int]$X, [int]$Y, [int]$R, [int]$G, [int]$B) {
    $c = $Bmp.GetPixel($X, $Y)
    return ($c.R -eq $R -and $c.G -eq $G -and $c.B -eq $B)
}

function Verify-Centered640x480([System.Drawing.Bitmap]$Bmp, [int]$LogicalW, [int]$LogicalH, [string]$Label) {
    if ($Bmp.Width -ne 640 -or $Bmp.Height -ne 480) {
        Write-Log "VERIFY_${Label}_FAIL:size=$($Bmp.Width)x$($Bmp.Height)"
        return $false
    }
    $ox = [int]((640 - $LogicalW) / 2)
    $oy = [int]((480 - $LogicalH) / 2)
    $ok = $true

    if ($ox -gt 0) {
        $ok = (Test-PixelExact $Bmp ([int]($ox / 2)) 240 0 0 0) -and $ok
        $ok = (Test-PixelExact $Bmp (639 - [int]($ox / 2)) 240 0 0 0) -and $ok
    }
    if ($oy -gt 0) {
        $ok = (Test-PixelExact $Bmp 320 ([int]($oy / 2)) 0 0 0) -and $ok
        $ok = (Test-PixelExact $Bmp 320 (479 - [int]($oy / 2)) 0 0 0) -and $ok
    }

    $ok = (Test-PixelExact $Bmp ($ox + [int]($LogicalW / 2)) ($oy + 2) 255 0 0) -and $ok
    $ok = (Test-PixelExact $Bmp ($ox + $LogicalW - 3) ($oy + [int]($LogicalH / 2)) 0 255 0) -and $ok
    $ok = (Test-PixelExact $Bmp ($ox + [int]($LogicalW / 2)) ($oy + $LogicalH - 3) 0 0 255) -and $ok
    $ok = (Test-PixelExact $Bmp ($ox + 2) ($oy + [int]($LogicalH / 2)) 255 255 0) -and $ok

    $cx = if ($LogicalW -ge 308 -and $LogicalH -ge 228) { 300 } else { [Math]::Max(4, [int]($LogicalW / 2) - 4) }
    $cy = if ($LogicalW -ge 308 -and $LogicalH -ge 228) { 220 } else { [Math]::Max(4, [int]($LogicalH / 2) - 4) }
    for ($y = 0; $y -lt 8; $y++) {
        for ($x = 0; $x -lt 8; $x++) {
            $want = if ((($x + $y) % 2) -eq 0) { 255 } else { 0 }
            $ok = (Test-PixelExact $Bmp ($ox + $cx + $x) ($oy + $cy + $y) $want $want $want) -and $ok
        }
    }

    Write-Log "VERIFY_${Label}:origin=${ox},${oy}:logical=${LogicalW}x${LogicalH}:ok=${ok}"
    return [bool]$ok
}

function Send-RunnerCommand([string]$ControlDir, [string]$Command) {
    $ack = Join-Path $ControlDir 'ack.txt'
    Remove-Item -LiteralPath $ack -ErrorAction SilentlyContinue
    Set-Content -LiteralPath (Join-Path $ControlDir 'command.txt') -Value $Command -NoNewline -Encoding UTF8
    $deadline = (Get-Date).AddSeconds(20)
    while (-not (Test-Path -LiteralPath $ack) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 50
    }
    if (-not (Test-Path -LiteralPath $ack)) {
        throw "Timeout waiting for ack to command '$Command'"
    }
    $result = (Get-Content -LiteralPath $ack -Raw).Trim()
    if ($result -match '(?m)^label=.*:fail\s*$') { throw "Runner rejected '$Command': $result" }
    return $result
}

function Start-GodotInteractive([string]$ControlDir, [string]$LogicalSize, [bool]$LegacyRed, [string]$LogName) {
    Remove-Item -LiteralPath $ControlDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $ControlDir | Out-Null
    $stdout = Join-Path $EvidenceDir "$LogName.stdout.log"
    $stderr = Join-Path $EvidenceDir "$LogName.stderr.log"
    Remove-Item -LiteralPath $stdout, $stderr -ErrorAction SilentlyContinue

    $argList = @('--path', $ProjectRoot, '-s', 'tests/test_original_fullscreen.gd', '--', '--interactive', '--control-dir', $ControlDir, '--logical-size', $LogicalSize)
    if ($LegacyRed) { $argList += '--legacy-godot-fullscreen' }

    $proc = Start-Process -FilePath $GodotPath -ArgumentList $argList -WorkingDirectory $ProjectRoot -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
    $ready = Join-Path $ControlDir 'ready.txt'
    $deadline = (Get-Date).AddSeconds(30)
    while (-not (Test-Path -LiteralPath $ready) -and (Get-Date) -lt $deadline -and -not $proc.HasExited) {
        Start-Sleep -Milliseconds 100
    }
    if (-not (Test-Path -LiteralPath $ready)) {
        throw "Godot interactive runner '$LogName' failed to reach ready.txt (exited=$($proc.HasExited))"
    }
    return $proc
}

$AllPassed = $true
$ActiveProc = $null

try {
    if ($FocusOnly) {
        $focusDir = Join-Path $TempDir 'focus-only'
        $ActiveProc = Start-GodotInteractive $focusDir '544x416' $false 'focus-order'
        $null = $ActiveProc.Handle
        $hwnd = [C12HostWin32]::FindProcessWindow([uint32]$ActiveProc.Id)
        [C12HostWin32]::EnsureForeground($hwnd) | Out-Null
        $entryCommand = if ($F1Entry) { 'f1_fullscreen:1' } else { 'alt_enter' }
        $entryStatus = Send-RunnerCommand $focusDir $entryCommand
        Write-Log "FOCUS_ONLY_ENTRY_STATUS:$entryStatus"
        $entered = [C12HostWin32]::GetCurrentMode()
        Write-Log "FOCUS_ONLY_ENTER:$([C12HostWin32]::FormatMode($entered))"
        $AllPassed = ($entered.dmPelsWidth -eq 640 -and $entered.dmPelsHeight -eq 480) -and $AllPassed
        if (-not $AllPassed) { throw 'Focus-only fullscreen entry precondition failed' }
        [void](Send-RunnerCommand $focusDir 'focus_out')
        $outMode = [C12HostWin32]::FormatMode([C12HostWin32]::GetCurrentMode())
        Write-Log "FOCUS_ONLY_OUT:$outMode"
        $AllPassed = ($outMode -eq $BaselineCurrentStr) -and $AllPassed
        [void](Send-RunnerCommand $focusDir 'focus_in')
        $resumed = [C12HostWin32]::GetCurrentMode()
        Write-Log "FOCUS_ONLY_IN:$([C12HostWin32]::FormatMode($resumed))"
        $AllPassed = ($resumed.dmPelsWidth -eq 640 -and $resumed.dmPelsHeight -eq 480) -and $AllPassed
        [void](Send-RunnerCommand $focusDir 'alt_enter')
        [void](Send-RunnerCommand $focusDir 'quit')
        if (-not $ActiveProc.WaitForExit(15000)) { throw 'Focus-only runner did not exit' }
        if ($ActiveProc.ExitCode -ne 0) { throw 'Focus-only runner failed' }
        $ActiveProc = $null
    } else {
    # Phase 1: Reproduce RED baseline (Godot 4.6 WindowMode.Fullscreen without Win32 display-mode switch).
    if (-not $SkipLegacyRed) {
        $redDir = Join-Path $TempDir 'red'
        Write-Log 'PHASE_RED_START'
        $ActiveProc = Start-GodotInteractive $redDir '640x480' $true 'red-legacy'
        $hwnd = [C12HostWin32]::FindProcessWindow([uint32]$ActiveProc.Id)
        [C12HostWin32]::EnsureForeground($hwnd) | Out-Null
        [void](Send-RunnerCommand $redDir 'alt_enter')
        Start-Sleep -Milliseconds 800
        $redMode = [C12HostWin32]::GetCurrentMode()
        $redModeStr = [C12HostWin32]::FormatMode($redMode)
        $redWin = [C12HostWin32]::DescribeWindow($hwnd)
        Write-Log "RED_FULLSCREEN_MODE:$redModeStr"
        Write-Log "RED_FULLSCREEN_WINDOW:$redWin"
        $redBmp = [C12HostWin32]::CaptureDesktop([int]$redMode.dmPelsWidth, [int]$redMode.dmPelsHeight)
        try {
            $redPng = Join-Path $EvidenceDir 'red-legacy-fullscreen-desktop.png'
            $redBmp.Save($redPng, [System.Drawing.Imaging.ImageFormat]::Png)
            # Confirm red behavior: physical display mode did NOT switch to 640x480; it stayed at baseline desktop resolution.
            $redReproduced = ($redMode.dmPelsWidth -eq $BaselineCurrent.dmPelsWidth -and $redMode.dmPelsHeight -eq $BaselineCurrent.dmPelsHeight -and $redMode.dmPelsWidth -ne 640)
            Write-Log "RED_REPRODUCED_DESKTOP_UNCHANGED:$redReproduced"
            $AllPassed = $redReproduced -and $AllPassed
        } finally {
            $redBmp.Dispose()
        }
        [void](Send-RunnerCommand $redDir 'alt_enter')
        Set-Content -LiteralPath (Join-Path $redDir 'stop.signal') -Value 'stop'
        if (-not $ActiveProc.WaitForExit(15000)) { $ActiveProc.Kill() }
        Write-Log "PHASE_RED_EXIT:$($ActiveProc.ExitCode)"
        $ActiveProc = $null
    }

    # Phase 2: Verify GREEN native Win32 CDS_FULLSCREEN + 1:1 centering (640x480, 544x416, 320x240) + F1 + focus + exit-in-fullscreen.
    if (-not $NonRegistryOnly) {
    $greenDir = Join-Path $TempDir 'green'
    Write-Log 'PHASE_GREEN_START'
    $ActiveProc = Start-GodotInteractive $greenDir '640x480' $false 'green-native'
    $hwnd = [C12HostWin32]::FindProcessWindow([uint32]$ActiveProc.Id)
    [C12HostWin32]::EnsureForeground($hwnd) | Out-Null

    foreach ($spec in @(
        @{ Name = '640x480'; W = 640; H = 480 },
        @{ Name = '544x416'; W = 544; H = 416 },
        @{ Name = '320x240'; W = 320; H = 240 }
    )) {
        [void](Send-RunnerCommand $greenDir "resize:$($spec.Name)")
        [C12HostWin32]::EnsureForeground($hwnd) | Out-Null
        [void](Send-RunnerCommand $greenDir 'alt_enter')
        Start-Sleep -Milliseconds 1200

        $fsMode = [C12HostWin32]::GetCurrentMode()
        $fsModeStr = [C12HostWin32]::FormatMode($fsMode)
        $fsWin = [C12HostWin32]::DescribeWindow($hwnd)
        Write-Log "GREEN_$($spec.Name)_FULLSCREEN_MODE:$fsModeStr"
        Write-Log "GREEN_$($spec.Name)_FULLSCREEN_WINDOW:$fsWin"
        $AllPassed = ($fsMode.dmPelsWidth -eq 640 -and $fsMode.dmPelsHeight -eq 480) -and $AllPassed

        [void](Send-RunnerCommand $greenDir "snapshot:$($spec.Name)")
        Copy-Item -LiteralPath (Join-Path $greenDir "viewport-$($spec.Name).png") -Destination (Join-Path $EvidenceDir "green-viewport-$($spec.Name).png") -Force
        if (Test-Path -LiteralPath (Join-Path $greenDir "screen-$($spec.Name).png")) {
            Copy-Item -LiteralPath (Join-Path $greenDir "screen-$($spec.Name).png") -Destination (Join-Path $EvidenceDir "green-godot-screen-$($spec.Name).png") -Force
        }

        [C12HostWin32]::EnsureForeground($hwnd) | Out-Null
        Start-Sleep -Milliseconds 250
        $bmp = [C12HostWin32]::CaptureDesktop([int]$fsMode.dmPelsWidth, [int]$fsMode.dmPelsHeight)
        try {
            $png = Join-Path $EvidenceDir "green-fullscreen-$($spec.Name)-desktop.png"
            $bmp.Save($png, [System.Drawing.Imaging.ImageFormat]::Png)
            $pixelOk = (Verify-Centered640x480 $bmp $spec.W $spec.H $spec.Name) -eq $true
            $AllPassed = $pixelOk -and $AllPassed
        } finally {
            $bmp.Dispose()
        }

        [void](Send-RunnerCommand $greenDir 'alt_enter')
        Start-Sleep -Milliseconds 1000
        $restoredMode = [C12HostWin32]::FormatMode([C12HostWin32]::GetCurrentMode())
        Write-Log "GREEN_$($spec.Name)_RESTORED_MODE:$restoredMode"
        $AllPassed = ($restoredMode -eq $BaselineCurrentStr) -and $AllPassed
    }

    # Verify F1 Game Properties dialog uses the unified native path + focus-out/focus-in lifecycle.
    [void](Send-RunnerCommand $greenDir 'resize:544x416')
    [C12HostWin32]::EnsureForeground($hwnd) | Out-Null
    [void](Send-RunnerCommand $greenDir 'f1_fullscreen:1')
    Start-Sleep -Milliseconds 1200
    [C12HostWin32]::EnsureForeground($hwnd) | Out-Null
    Start-Sleep -Milliseconds 250
    $f1Mode = [C12HostWin32]::GetCurrentMode()
    Write-Log "GREEN_F1_FULLSCREEN_MODE:$([C12HostWin32]::FormatMode($f1Mode))"
    $AllPassed = ($f1Mode.dmPelsWidth -eq 640 -and $f1Mode.dmPelsHeight -eq 480) -and $AllPassed

    $f1Bmp = [C12HostWin32]::CaptureDesktop([int]$f1Mode.dmPelsWidth, [int]$f1Mode.dmPelsHeight)
    try {
        $f1Bmp.Save((Join-Path $EvidenceDir 'green-f1-544x416-desktop.png'), [System.Drawing.Imaging.ImageFormat]::Png)
        $f1Ok = (Verify-Centered640x480 $f1Bmp 544 416 'F1_544x416') -eq $true
        $AllPassed = $f1Ok -and $AllPassed
    } finally {
        $f1Bmp.Dispose()
    }

    # Focus-out restores prior desktop mode; focus-in re-enters 640x480 fullscreen.
    [void](Send-RunnerCommand $greenDir 'focus_out')
    Start-Sleep -Milliseconds 900
    $focusOutMode = [C12HostWin32]::FormatMode([C12HostWin32]::GetCurrentMode())
    Write-Log "GREEN_FOCUS_OUT_MODE:$focusOutMode"
    $AllPassed = ($focusOutMode -eq $BaselineCurrentStr) -and $AllPassed

    [void](Send-RunnerCommand $greenDir 'focus_in')
    Start-Sleep -Milliseconds 1200
    $focusInMode = [C12HostWin32]::GetCurrentMode()
    Write-Log "GREEN_FOCUS_IN_MODE:$([C12HostWin32]::FormatMode($focusInMode))"
    $AllPassed = ($focusInMode.dmPelsWidth -eq 640 -and $focusInMode.dmPelsHeight -eq 480) -and $AllPassed

    # Reset persisted F1 fullscreen=false before testing exit-while-fullscreen via Alt+Enter.
    [void](Send-RunnerCommand $greenDir 'f1_fullscreen:0')
    Start-Sleep -Milliseconds 900
    $afterF1Off = [C12HostWin32]::FormatMode([C12HostWin32]::GetCurrentMode())
    Write-Log "GREEN_F1_OFF_MODE:$afterF1Off"
    $AllPassed = ($afterF1Off -eq $BaselineCurrentStr) -and $AllPassed

    # Re-enter fullscreen via Alt+Enter and exit process while still in fullscreen.
    [C12HostWin32]::EnsureForeground($hwnd) | Out-Null
    [void](Send-RunnerCommand $greenDir 'alt_enter')
    Start-Sleep -Milliseconds 1000
    $preExitMode = [C12HostWin32]::GetCurrentMode()
    Write-Log "GREEN_PRE_EXIT_MODE:$([C12HostWin32]::FormatMode($preExitMode))"
    $AllPassed = ($preExitMode.dmPelsWidth -eq 640 -and $preExitMode.dmPelsHeight -eq 480) -and $AllPassed

    [C12HostWin32]::EnsureForeground($hwnd) | Out-Null
    Set-Content -LiteralPath (Join-Path $greenDir 'stop.signal') -Value 'stop'
    $exited = $ActiveProc.WaitForExit(25000)
    $exitCode = if ($exited) { [int]$ActiveProc.ExitCode } else { -1 }
    Write-Log "GREEN_EXIT_WHILE_FULLSCREEN:exited=${exited}:code=${exitCode}"
    Start-Sleep -Milliseconds 1000
    $postExitCurrent = [C12HostWin32]::FormatMode([C12HostWin32]::GetCurrentMode())
    $postExitRegistry = [C12HostWin32]::FormatMode([C12HostWin32]::GetRegistryMode())
    Write-Log "GREEN_POST_EXIT_CURRENT:${postExitCurrent}"
    Write-Log "GREEN_POST_EXIT_REGISTRY:${postExitRegistry}"
    $AllPassed = $exited -and ($exitCode -eq 0) -and ($postExitCurrent -eq $BaselineCurrentStr) -and ($postExitRegistry -eq $BaselineRegistryStr) -and $AllPassed
    $ActiveProc = $null

    # Phase 3: Prove RestorePreviousMode restores exact non-registry savedMode (not ENUM_REGISTRY_SETTINGS) across toggle, focus, and exit.
    }
    $nonRegMode = New-Object C12HostWin32+DEVMODEW
    if ([C12HostWin32]::TryFindNonRegistryMode($BaselineRegistry, $AlternateRefreshRate, [ref]$nonRegMode)) {
        $nonRegDir = Join-Path $TempDir 'non-registry'
        $rcSet = [C12HostWin32]::ApplyDynamicMode($nonRegMode)
        Start-Sleep -Milliseconds 1000
        $sessionStartStr = [C12HostWin32]::FormatMode([C12HostWin32]::GetCurrentMode())
        $regCheckStr = [C12HostWin32]::FormatMode([C12HostWin32]::GetRegistryMode())
        Write-Log "PHASE_NONREG_START:rc=${rcSet}:sessionStart=${sessionStartStr}:registry=${regCheckStr}"
        $AllPassed = ($rcSet -eq 0) -and ($sessionStartStr -ne $BaselineRegistryStr) -and ($regCheckStr -eq $BaselineRegistryStr) -and $AllPassed

        $ActiveProc = Start-GodotInteractive $nonRegDir '544x416' $false 'green-nonregistry'
        $hwndNonReg = [C12HostWin32]::FindProcessWindow([uint32]$ActiveProc.Id)
        [C12HostWin32]::EnsureForeground($hwndNonReg) | Out-Null

        # Toggle into fullscreen -> 640x480
        [void](Send-RunnerCommand $nonRegDir 'alt_enter')
        Start-Sleep -Milliseconds 1100
        $nonRegFs = [C12HostWin32]::GetCurrentMode()
        Write-Log "NONREG_FULLSCREEN_MODE:$([C12HostWin32]::FormatMode($nonRegFs))"
        $AllPassed = ($nonRegFs.dmPelsWidth -eq 640 -and $nonRegFs.dmPelsHeight -eq 480) -and $AllPassed

        # Focus-out -> must restore non-registry sessionStartStr (e.g. 60Hz), NOT registry 144Hz
        [void](Send-RunnerCommand $nonRegDir 'focus_out')
        Start-Sleep -Milliseconds 1000
        $nonRegFocusOut = [C12HostWin32]::FormatMode([C12HostWin32]::GetCurrentMode())
        Write-Log "NONREG_FOCUS_OUT_MODE:${nonRegFocusOut}:expected=${sessionStartStr}"
        $AllPassed = ($nonRegFocusOut -eq $sessionStartStr) -and $AllPassed

        # Focus-in -> back to 640x480
        [void](Send-RunnerCommand $nonRegDir 'focus_in')
        Start-Sleep -Milliseconds 1100
        $nonRegFocusIn = [C12HostWin32]::GetCurrentMode()
        Write-Log "NONREG_FOCUS_IN_MODE:$([C12HostWin32]::FormatMode($nonRegFocusIn))"
        $AllPassed = ($nonRegFocusIn.dmPelsWidth -eq 640 -and $nonRegFocusIn.dmPelsHeight -eq 480) -and $AllPassed

        # Toggle out -> must restore non-registry sessionStartStr
        [void](Send-RunnerCommand $nonRegDir 'alt_enter')
        Start-Sleep -Milliseconds 1000
        $nonRegToggledOut = [C12HostWin32]::FormatMode([C12HostWin32]::GetCurrentMode())
        Write-Log "NONREG_TOGGLE_OUT_MODE:${nonRegToggledOut}:expected=${sessionStartStr}"
        $AllPassed = ($nonRegToggledOut -eq $sessionStartStr) -and $AllPassed

        # Re-enter fullscreen and exit while fullscreen -> must restore non-registry sessionStartStr, registry still unchanged
        [C12HostWin32]::EnsureForeground($hwndNonReg) | Out-Null
        [void](Send-RunnerCommand $nonRegDir 'alt_enter')
        Start-Sleep -Milliseconds 1000
        [C12HostWin32]::EnsureForeground($hwndNonReg) | Out-Null
        Set-Content -LiteralPath (Join-Path $nonRegDir 'stop.signal') -Value 'stop'
        $nonRegExited = $ActiveProc.WaitForExit(25000)
        $nonRegExitCode = if ($nonRegExited) { [int]$ActiveProc.ExitCode } else { -1 }
        Start-Sleep -Milliseconds 1000
        $nonRegPostExit = [C12HostWin32]::FormatMode([C12HostWin32]::GetCurrentMode())
        $nonRegPostRegistry = [C12HostWin32]::FormatMode([C12HostWin32]::GetRegistryMode())
        Write-Log "NONREG_POST_EXIT:exited=${nonRegExited}:code=${nonRegExitCode}:current=${nonRegPostExit}:expected=${sessionStartStr}:registry=${nonRegPostRegistry}"
        $AllPassed = $nonRegExited -and ($nonRegExitCode -eq 0) -and ($nonRegPostExit -eq $sessionStartStr) -and ($nonRegPostRegistry -eq $BaselineRegistryStr) -and $AllPassed
        $ActiveProc = $null

        # Restore workstation's original baseline mode cleanly
        $rcRestoreBase = [C12HostWin32]::ApplyDynamicMode($BaselineCurrent)
        Start-Sleep -Milliseconds 1000
        $restoredBaseStr = [C12HostWin32]::FormatMode([C12HostWin32]::GetCurrentMode())
        Write-Log "PHASE_NONREG_BASELINE_RESTORE:rc=${rcRestoreBase}:current=${restoredBaseStr}:expected=${BaselineCurrentStr}"
        $AllPassed = ($rcRestoreBase -eq 0) -and ($restoredBaseStr -eq $BaselineCurrentStr) -and $AllPassed
    } else {
        Write-Log 'PHASE_NONREG_SKIPPED:no_alternate_refresh_mode_available_on_driver'
        $AllPassed = $false
    }
    }
}
finally {
    if ($null -ne $ActiveProc -and -not $ActiveProc.HasExited) {
        try { $ActiveProc.Kill() } catch { }
    }
    $curAfter = [C12HostWin32]::FormatMode([C12HostWin32]::GetCurrentMode())
    if ($curAfter -ne $BaselineCurrentStr) {
        Write-Log "EMERGENCY_RESTORE_TRIGGERED:from=$curAfter:to=$BaselineCurrentStr"
        $rc = [C12HostWin32]::ForceRestoreMode($BaselineCurrent)
        Start-Sleep -Milliseconds 1000
        Write-Log "EMERGENCY_RESTORE_RESULT:rc=$rc:now=$([C12HostWin32]::FormatMode([C12HostWin32]::GetCurrentMode()))"
        $AllPassed = $false
    }
}

Write-Log ("ORIGINAL_FULLSCREEN_HARNESS_RESULT:" + $(if ($AllPassed) { 'PASS' } else { 'FAIL' }))
exit $(if ($AllPassed) { 0 } else { 1 })
