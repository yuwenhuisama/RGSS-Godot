using System;
using System.Runtime.InteropServices;

namespace RGSSUnity;

internal static class WindowsDisplayMode
{
    public const int FullscreenWidth = 640;
    public const int FullscreenHeight = 480;

    private const int EnumCurrentSettings = -1;
    private const uint CdsTest = 0x00000002;
    private const uint CdsFullscreen = 0x00000004;
    private const int DispChangeSuccessful = 0;
    private const uint MonitorDefaultToNearest = 0x00000002;

    private const uint DmBitsPerPel = 0x00040000;
    private const uint DmPelsWidth = 0x00080000;
    private const uint DmPelsHeight = 0x00100000;
    private const uint DmDisplayFlags = 0x00200000;
    private const uint DmDisplayFrequency = 0x00400000;
    private const uint DmDisplayFixedOutput = 0x20000000;

    private static readonly object Sync = new();
    private static string? activeDeviceName;
    private static DEVMODEW? savedMode;
    private static bool exitHookRegistered;
    private static nint presenterHwnd;
    private static byte[]? presenterBgraBuffer;

    public readonly record struct DisplayModeSnapshot(
        string DeviceName,
        int Width,
        int Height,
        int BitsPerPel,
        int Frequency,
        uint FixedOutput);

    public readonly record struct DisplaySwitchResult(
        bool Success,
        int ReturnCode,
        DisplayModeSnapshot PreviousMode,
        DisplayModeSnapshot TargetMode,
        string Message);

    public static bool IsSupportedHost
        => OperatingSystem.IsWindows();

    public static bool IsActive
    {
        get
        {
            lock (Sync)
                return activeDeviceName is not null;
        }
    }

    public static string? ResolveMonitorDeviceName(nint windowHandle)
    {
        if (!OperatingSystem.IsWindows() || windowHandle == nint.Zero)
            return null;

        var monitor = MonitorFromWindow(windowHandle, MonitorDefaultToNearest);
        if (monitor == nint.Zero)
            return null;

        var info = new MONITORINFOEXW { cbSize = Marshal.SizeOf<MONITORINFOEXW>() };
        if (!GetMonitorInfoW(monitor, ref info) || string.IsNullOrWhiteSpace(info.szDevice))
            return null;

        return info.szDevice;
    }

    public static bool TryGetPhysicalMonitorRect(string? deviceName, nint fallbackHwnd, out Godot.Rect2I monitorRect)
    {
        monitorRect = default;
        if (!OperatingSystem.IsWindows())
            return false;

        var prev = TryPushPerMonitorDpiContext();
        try
        {
            if (!string.IsNullOrWhiteSpace(deviceName))
            {
                Godot.Rect2I foundRect = default;
                var found = false;
                MonitorEnumProc callback = (nint hMonitor, nint hdc, ref RECT rect, nint data) =>
                {
                    var info = new MONITORINFOEXW { cbSize = Marshal.SizeOf<MONITORINFOEXW>() };
                    if (GetMonitorInfoW(hMonitor, ref info)
                        && string.Equals(info.szDevice, deviceName, StringComparison.OrdinalIgnoreCase))
                    {
                        foundRect = new Godot.Rect2I(
                            info.rcMonitor.Left,
                            info.rcMonitor.Top,
                            info.rcMonitor.Right - info.rcMonitor.Left,
                            info.rcMonitor.Bottom - info.rcMonitor.Top);
                        found = true;
                        return false;
                    }
                    return true;
                };
                _ = EnumDisplayMonitors(nint.Zero, nint.Zero, callback, nint.Zero);
                if (found)
                {
                    monitorRect = foundRect;
                    return true;
                }
            }

            if (fallbackHwnd != nint.Zero)
            {
                var monitor = MonitorFromWindow(fallbackHwnd, MonitorDefaultToNearest);
                if (monitor != nint.Zero)
                {
                    var info = new MONITORINFOEXW { cbSize = Marshal.SizeOf<MONITORINFOEXW>() };
                    if (GetMonitorInfoW(monitor, ref info))
                    {
                        monitorRect = new Godot.Rect2I(
                            info.rcMonitor.Left,
                            info.rcMonitor.Top,
                            info.rcMonitor.Right - info.rcMonitor.Left,
                            info.rcMonitor.Bottom - info.rcMonitor.Top);
                        return true;
                    }
                }
            }

            return false;
        }
        finally
        {
            RestoreDpiContext(prev);
        }
    }

    public static void EnforcePhysicalTopmostRect(nint windowHandle, int x, int y, int width, int height)
    {
        if (!OperatingSystem.IsWindows() || windowHandle == nint.Zero)
            return;

        var prev = TryPushPerMonitorDpiContext();
        try
        {
            const nint hwndTopMost = -1;
            const uint swpFrameChanged = 0x0020;
            const uint swpShowWindow = 0x0040;
            const uint swpNoActivate = 0x0010;
            _ = SetWindowPos(windowHandle, hwndTopMost, x, y, width, height, swpFrameChanged | swpShowWindow | swpNoActivate);
        }
        finally
        {
            RestoreDpiContext(prev);
        }
    }

    public static nint PushPerMonitorDpiContext()
        => TryPushPerMonitorDpiContext();

    public static void PopDpiContext(nint previous)
        => RestoreDpiContext(previous);

    public static bool TryGetLogicalMonitorRect(string? deviceName, nint fallbackHwnd, out Godot.Rect2I monitorRect)
    {
        monitorRect = default;
        if (!OperatingSystem.IsWindows())
            return false;

        if (!string.IsNullOrWhiteSpace(deviceName))
        {
            Godot.Rect2I foundRect = default;
            var found = false;
            MonitorEnumProc callback = (nint hMonitor, nint hdc, ref RECT rect, nint data) =>
            {
                var info = new MONITORINFOEXW { cbSize = Marshal.SizeOf<MONITORINFOEXW>() };
                if (GetMonitorInfoW(hMonitor, ref info)
                    && string.Equals(info.szDevice, deviceName, StringComparison.OrdinalIgnoreCase))
                {
                    foundRect = new Godot.Rect2I(
                        info.rcMonitor.Left,
                        info.rcMonitor.Top,
                        info.rcMonitor.Right - info.rcMonitor.Left,
                        info.rcMonitor.Bottom - info.rcMonitor.Top);
                    found = true;
                    return false;
                }
                return true;
            };
            _ = EnumDisplayMonitors(nint.Zero, nint.Zero, callback, nint.Zero);
            if (found)
            {
                monitorRect = foundRect;
                return true;
            }
        }

        if (fallbackHwnd != nint.Zero)
        {
            var monitor = MonitorFromWindow(fallbackHwnd, MonitorDefaultToNearest);
            if (monitor != nint.Zero)
            {
                var info = new MONITORINFOEXW { cbSize = Marshal.SizeOf<MONITORINFOEXW>() };
                if (GetMonitorInfoW(monitor, ref info))
                {
                    monitorRect = new Godot.Rect2I(
                        info.rcMonitor.Left,
                        info.rcMonitor.Top,
                        info.rcMonitor.Right - info.rcMonitor.Left,
                        info.rcMonitor.Bottom - info.rcMonitor.Top);
                    return true;
                }
            }
        }

        return false;
    }

    public static string? ActiveDeviceName
    {
        get
        {
            lock (Sync)
                return activeDeviceName;
        }
    }

    public static void EnforceTopmostFullscreenRect(nint windowHandle, int x, int y, int width, int height)
    {
        if (!OperatingSystem.IsWindows() || windowHandle == nint.Zero)
            return;

        const nint hwndTopMost = -1;
        const uint swpFrameChanged = 0x0020;
        const uint swpShowWindow = 0x0040;
        _ = SetWindowPos(windowHandle, hwndTopMost, x, y, width, height, swpFrameChanged | swpShowWindow);
    }

    public static void ClearTopmostFlag(nint windowHandle)
    {
        if (!OperatingSystem.IsWindows() || windowHandle == nint.Zero)
            return;

        const nint hwndNoTopMost = -2;
        const uint swpNoMove = 0x0002;
        const uint swpNoSize = 0x0001;
        const uint swpNoActivate = 0x0010;
        _ = SetWindowPos(windowHandle, hwndNoTopMost, 0, 0, 0, 0, swpNoMove | swpNoSize | swpNoActivate);
    }

    public static Godot.Vector2I GetClientSizeWin32(nint windowHandle)
    {
        if (!OperatingSystem.IsWindows() || windowHandle == nint.Zero)
            return Godot.Vector2I.Zero;

        var prev = TryPushPerMonitorDpiContext();
        try
        {
            if (GetClientRect(windowHandle, out var rect))
                return new Godot.Vector2I(rect.Right - rect.Left, rect.Bottom - rect.Top);
            return Godot.Vector2I.Zero;
        }
        finally
        {
            RestoreDpiContext(prev);
        }
    }

    private static nint TryPushPerMonitorDpiContext()
    {
        try
        {
            return SetThreadDpiAwarenessContext(new nint(-4));
        }
        catch
        {
            return nint.Zero;
        }
    }

    private static void RestoreDpiContext(nint previous)
    {
        if (previous == nint.Zero)
            return;
        try
        {
            _ = SetThreadDpiAwarenessContext(previous);
        }
        catch
        {
        }
    }

    public static Godot.Vector2I GetWindowPositionWin32(nint windowHandle)
    {
        if (OperatingSystem.IsWindows() && windowHandle != nint.Zero && GetWindowRect(windowHandle, out var rect))
            return new Godot.Vector2I(rect.Left, rect.Top);
        return Godot.Vector2I.Zero;
    }

    public static void MoveWindowWin32(nint windowHandle, int x, int y)
    {
        if (!OperatingSystem.IsWindows() || windowHandle == nint.Zero)
            return;
        const uint swpNoSize = 0x0001;
        const uint swpNoZOrder = 0x0004;
        const uint swpNoActivate = 0x0010;
        _ = SetWindowPos(windowHandle, nint.Zero, x, y, 0, 0, swpNoSize | swpNoZOrder | swpNoActivate);
    }

    public static bool TryGetCurrentMode(string? deviceName, out DisplayModeSnapshot snapshot)
    {
        snapshot = default;
        if (!OperatingSystem.IsWindows())
            return false;

        var mode = CreateDevMode();
        if (!EnumDisplaySettingsW(deviceName, EnumCurrentSettings, ref mode))
            return false;

        snapshot = ToSnapshot(deviceName ?? string.Empty, in mode);
        return true;
    }

    public static DisplaySwitchResult EnterFullscreenMode(nint windowHandle, int requestedLogicalWidth, int requestedLogicalHeight)
    {
        if (!OperatingSystem.IsWindows())
        {
            return new DisplaySwitchResult(
                false,
                -1,
                default,
                default,
                "Windows native display-mode switching is only supported on Windows.");
        }

        EnsureExitHooks();

        lock (Sync)
        {
            var deviceName = activeDeviceName ?? ResolveMonitorDeviceName(windowHandle);
            var current = CreateDevMode();
            if (!EnumDisplaySettingsW(deviceName, EnumCurrentSettings, ref current))
            {
                return new DisplaySwitchResult(
                    false,
                    -2,
                    default,
                    default,
                    $"EnumDisplaySettingsW(ENUM_CURRENT_SETTINGS) failed for '{deviceName ?? "<primary>"}'.");
            }

            var baseline = savedMode ?? current;
            var baselineSnapshot = ToSnapshot(deviceName ?? string.Empty, in baseline);

            var targetWidth = Math.Clamp(requestedLogicalWidth, 1, FullscreenWidth);
            var targetHeight = Math.Clamp(requestedLogicalHeight, 1, FullscreenHeight);

            if (!TrySelectFullscreenCandidate(deviceName, in baseline, targetWidth, targetHeight, out var target)
                && (targetWidth != FullscreenWidth || targetHeight != FullscreenHeight))
            {
                _ = TrySelectFullscreenCandidate(deviceName, in baseline, FullscreenWidth, FullscreenHeight, out target);
            }

            if (target.dmPelsWidth == 0 || target.dmPelsHeight == 0)
            {
                return new DisplaySwitchResult(
                    false,
                    -3,
                    baselineSnapshot,
                    default,
                    $"No supported CDS_FULLSCREEN display mode found for logical {targetWidth}x{targetHeight} or fallback {FullscreenWidth}x{FullscreenHeight} on '{deviceName ?? "<primary>"}'.");
            }

            var targetSnapshot = ToSnapshot(deviceName ?? string.Empty, in target);
            if (activeDeviceName is not null
                && string.Equals(activeDeviceName, deviceName ?? string.Empty, StringComparison.OrdinalIgnoreCase)
                && current.dmPelsWidth == target.dmPelsWidth
                && current.dmPelsHeight == target.dmPelsHeight)
            {
                return new DisplaySwitchResult(true, DispChangeSuccessful, baselineSnapshot, targetSnapshot, "Already in target fullscreen display mode.");
            }

            var applyMode = BuildFullscreenDevMode(in target);
            var rc = ChangeDisplaySettingsExW(deviceName, ref applyMode, nint.Zero, CdsFullscreen, nint.Zero);
            if (rc != DispChangeSuccessful)
            {
                return new DisplaySwitchResult(
                    false,
                    rc,
                    baselineSnapshot,
                    targetSnapshot,
                    $"ChangeDisplaySettingsExW(CDS_FULLSCREEN) failed with code {rc} ({DescribeReturnCode(rc)}) for {targetSnapshot.Width}x{targetSnapshot.Height}@{targetSnapshot.Frequency}Hz on '{deviceName ?? "<primary>"}'.");
            }

            savedMode ??= current;
            activeDeviceName = deviceName ?? string.Empty;
            return new DisplaySwitchResult(true, DispChangeSuccessful, baselineSnapshot, targetSnapshot, "Switched display mode with CDS_FULLSCREEN.");
        }
    }

    public static bool RestorePreviousMode(out int returnCode, out string message)
    {
        returnCode = DispChangeSuccessful;
        message = "No active fullscreen display-mode override.";

        if (!OperatingSystem.IsWindows())
            return true;

        lock (Sync)
        {
            if (activeDeviceName is null)
                return true;

            if (savedMode is not DEVMODEW previous)
            {
                returnCode = -1;
                message = $"Active fullscreen display-mode override on '{(activeDeviceName.Length == 0 ? "<primary>" : activeDeviceName)}' has no saved DEVMODEW snapshot to restore.";
                return false;
            }

            var deviceArg = activeDeviceName.Length == 0 ? null : activeDeviceName;
            var explicitRestore = previous;
            explicitRestore.dmSize = (ushort)Marshal.SizeOf<DEVMODEW>();
            var rc = ChangeDisplaySettingsExW(deviceArg, ref explicitRestore, nint.Zero, 0, nint.Zero);
            returnCode = rc;
            if (rc != DispChangeSuccessful)
            {
                message = $"ChangeDisplaySettingsExW(savedMode {explicitRestore.dmPelsWidth}x{explicitRestore.dmPelsHeight}@{explicitRestore.dmDisplayFrequency}Hz) failed with code {rc} ({DescribeReturnCode(rc)}) on '{deviceArg ?? "<primary>"}'.";
                return false;
            }

            activeDeviceName = null;
            savedMode = null;
            message = "Restored saved previous display mode.";
            return true;
        }
    }

    private static void EnsureExitHooks()
    {
        lock (Sync)
        {
            if (exitHookRegistered)
                return;

            AppDomain.CurrentDomain.ProcessExit += OnProcessExit;
            AppDomain.CurrentDomain.UnhandledException += OnUnhandledException;
            exitHookRegistered = true;
        }
    }

    private static void OnProcessExit(object? sender, EventArgs e)
    {
        DestroyPhysicalPresenter();
        _ = RestorePreviousMode(out _, out _);
    }

    private static void OnUnhandledException(object sender, UnhandledExceptionEventArgs e)
    {
        DestroyPhysicalPresenter();
        _ = RestorePreviousMode(out _, out _);
    }

    public static void PresentPhysicalCenteredRgba(
        nint rootHwnd,
        string? deviceName,
        int physicalWidth,
        int physicalHeight,
        int srcWidth,
        int srcHeight,
        int logicalWidth,
        int logicalHeight,
        ReadOnlySpan<byte> rgba)
    {
        if (!OperatingSystem.IsWindows() || physicalWidth <= 0 || physicalHeight <= 0 || srcWidth <= 0 || srcHeight <= 0)
            return;

        if (rgba.Length < srcWidth * srcHeight * 4)
            return;

        if (!TryGetPhysicalMonitorRect(deviceName, rootHwnd, out var monRect)
            || monRect.Size.X <= 0 || monRect.Size.Y <= 0)
        {
            monRect = new Godot.Rect2I(0, 0, physicalWidth, physicalHeight);
        }

        const uint wsPopup = 0x80000000u;
        const uint wsVisible = 0x10000000u;
        const uint wsExTopmost = 0x00000008u;
        const uint wsExToolWindow = 0x00000080u;
        const uint wsExNoActivate = 0x08000000u;
        const uint wsExTransparent = 0x00000020u;

        var prevDpi = TryPushPerMonitorDpiContext();
        try
        {
            if (presenterHwnd == nint.Zero || !IsWindow(presenterHwnd))
            {
                presenterHwnd = CreateWindowExW(
                    wsExTopmost | wsExToolWindow | wsExNoActivate | wsExTransparent,
                    "STATIC",
                    string.Empty,
                    wsPopup | wsVisible,
                    monRect.Position.X,
                    monRect.Position.Y,
                    physicalWidth,
                    physicalHeight,
                    nint.Zero,
                    nint.Zero,
                    nint.Zero,
                    nint.Zero);
            }

            if (presenterHwnd == nint.Zero)
                return;

            const nint hwndTopMost = -1;
            const uint swpNoActivate = 0x0010u;
            const uint swpShowWindow = 0x0040u;
            _ = SetWindowPos(
                presenterHwnd,
                hwndTopMost,
                monRect.Position.X,
                monRect.Position.Y,
                physicalWidth,
                physicalHeight,
                swpNoActivate | swpShowWindow);

            var requiredBytes = physicalWidth * physicalHeight * 4;
            if (presenterBgraBuffer is null || presenterBgraBuffer.Length != requiredBytes)
                presenterBgraBuffer = new byte[requiredBytes];
            else
                Array.Clear(presenterBgraBuffer, 0, requiredBytes);

            var copyW = Math.Min(Math.Min(logicalWidth, srcWidth), physicalWidth);
            var copyH = Math.Min(Math.Min(logicalHeight, srcHeight), physicalHeight);
            var ox = (physicalWidth - copyW) / 2;
            var oy = (physicalHeight - copyH) / 2;

            for (var y = 0; y < copyH; y++)
            {
                var srcRow = y * srcWidth * 4;
                var dstRow = ((oy + y) * physicalWidth + ox) * 4;
                for (var x = 0; x < copyW; x++)
                {
                    var s = srcRow + x * 4;
                    var d = dstRow + x * 4;
                    presenterBgraBuffer[d + 0] = rgba[s + 2];
                    presenterBgraBuffer[d + 1] = rgba[s + 1];
                    presenterBgraBuffer[d + 2] = rgba[s + 0];
                    presenterBgraBuffer[d + 3] = 255;
                }
            }

            var bmi = new BITMAPINFOHEADER
            {
                biSize = (uint)Marshal.SizeOf<BITMAPINFOHEADER>(),
                biWidth = physicalWidth,
                biHeight = -physicalHeight,
                biPlanes = 1,
                biBitCount = 32,
                biCompression = 0,
                biSizeImage = (uint)requiredBytes,
            };

            var hdc = GetDC(presenterHwnd);
            if (hdc != nint.Zero)
            {
                try
                {
                    _ = SetDIBitsToDevice(
                        hdc,
                        0,
                        0,
                        (uint)physicalWidth,
                        (uint)physicalHeight,
                        0,
                        0,
                        0,
                        (uint)physicalHeight,
                        presenterBgraBuffer,
                        ref bmi,
                        0);
                }
                finally
                {
                    _ = ReleaseDC(presenterHwnd, hdc);
                }
            }
        }
        finally
        {
            RestoreDpiContext(prevDpi);
        }
    }

    public static void DestroyPhysicalPresenter()
    {
        if (!OperatingSystem.IsWindows())
            return;

        if (presenterHwnd != nint.Zero)
        {
            if (IsWindow(presenterHwnd))
                _ = DestroyWindow(presenterHwnd);
            presenterHwnd = nint.Zero;
        }
    }

    private static bool TrySelectFullscreenCandidate(
        string? deviceName,
        in DEVMODEW baseline,
        int width,
        int height,
        out DEVMODEW selected)
    {
        selected = default;
        var candidate = CreateDevMode();
        var bestScore = int.MinValue;
        var modeIndex = 0;

        while (EnumDisplaySettingsW(deviceName, modeIndex++, ref candidate))
        {
            if (candidate.dmPelsWidth != (uint)width || candidate.dmPelsHeight != (uint)height)
                continue;

            var testMode = BuildFullscreenDevMode(in candidate);
            if (ChangeDisplaySettingsExW(deviceName, ref testMode, nint.Zero, CdsTest, nint.Zero) != DispChangeSuccessful)
                continue;

            var score = 0;
            if (candidate.dmBitsPerPel == baseline.dmBitsPerPel)
                score += 10000;
            else if (candidate.dmBitsPerPel >= 32)
                score += 5000;

            if (candidate.dmDisplayFrequency == baseline.dmDisplayFrequency)
                score += 1000;
            else
                score -= (int)Math.Abs((long)candidate.dmDisplayFrequency - baseline.dmDisplayFrequency);

            if (candidate.dmDisplayFixedOutput == 0)
                score += 200;
            else if (candidate.dmDisplayFixedOutput == 2)
                score += 100;

            if ((candidate.dmDisplayFlags & 0x00000002u) == 0)
                score += 50;

            if (score > bestScore)
            {
                bestScore = score;
                selected = candidate;
            }
        }

        return bestScore != int.MinValue;
    }

    private static DEVMODEW BuildFullscreenDevMode(in DEVMODEW source)
    {
        var mode = CreateDevMode();
        mode.dmBitsPerPel = source.dmBitsPerPel;
        mode.dmPelsWidth = source.dmPelsWidth;
        mode.dmPelsHeight = source.dmPelsHeight;
        mode.dmDisplayFlags = source.dmDisplayFlags;
        mode.dmDisplayFrequency = source.dmDisplayFrequency;
        mode.dmDisplayFixedOutput = source.dmDisplayFixedOutput;
        mode.dmFields = DmPelsWidth | DmPelsHeight;
        if (source.dmBitsPerPel != 0)
            mode.dmFields |= DmBitsPerPel;
        if (source.dmDisplayFrequency != 0)
            mode.dmFields |= DmDisplayFrequency;
        mode.dmFields |= DmDisplayFlags;
        if ((source.dmFields & DmDisplayFixedOutput) != 0)
            mode.dmFields |= DmDisplayFixedOutput;
        return mode;
    }

    private static DEVMODEW CreateDevMode()
        => new() { dmSize = (ushort)Marshal.SizeOf<DEVMODEW>() };

    private static DisplayModeSnapshot ToSnapshot(string deviceName, in DEVMODEW mode)
        => new(
            deviceName,
            (int)mode.dmPelsWidth,
            (int)mode.dmPelsHeight,
            (int)mode.dmBitsPerPel,
            (int)mode.dmDisplayFrequency,
            mode.dmDisplayFixedOutput);

    private static string DescribeReturnCode(int code)
        => code switch
        {
            0 => "DISP_CHANGE_SUCCESSFUL",
            1 => "DISP_CHANGE_RESTART",
            -1 => "DISP_CHANGE_FAILED",
            -2 => "DISP_CHANGE_BADMODE",
            -3 => "DISP_CHANGE_NOTUPDATED",
            -4 => "DISP_CHANGE_BADFLAGS",
            -5 => "DISP_CHANGE_BADPARAM",
            -6 => "DISP_CHANGE_BADDUALVIEW",
            _ => "DISP_CHANGE_UNKNOWN",
        };

    [StructLayout(LayoutKind.Sequential)]
    private struct BITMAPINFOHEADER
    {
        public uint biSize;
        public int biWidth;
        public int biHeight;
        public ushort biPlanes;
        public ushort biBitCount;
        public uint biCompression;
        public uint biSizeImage;
        public int biXPelsPerMeter;
        public int biYPelsPerMeter;
        public uint biClrUsed;
        public uint biClrImportant;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct MONITORINFOEXW
    {
        public int cbSize;
        public RECT rcMonitor;
        public RECT rcWork;
        public uint dwFlags;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string szDevice;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct DEVMODEW
    {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;

        public ushort dmSpecVersion;
        public ushort dmDriverVersion;
        public ushort dmSize;
        public ushort dmDriverExtra;
        public uint dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public uint dmDisplayOrientation;
        public uint dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;

        public ushort dmLogPixels;
        public uint dmBitsPerPel;
        public uint dmPelsWidth;
        public uint dmPelsHeight;
        public uint dmDisplayFlags;
        public uint dmDisplayFrequency;
        public uint dmICMMethod;
        public uint dmICMIntent;
        public uint dmMediaType;
        public uint dmDitherType;
        public uint dmReserved1;
        public uint dmReserved2;
        public uint dmPanningWidth;
        public uint dmPanningHeight;
    }

    private delegate bool MonitorEnumProc(nint hMonitor, nint hdcMonitor, ref RECT lprcMonitor, nint dwData);

    [DllImport("user32.dll")]
    private static extern bool EnumDisplayMonitors(nint hdc, nint lprcClip, MonitorEnumProc lpfnEnum, nint dwData);

    [DllImport("user32.dll")]
    private static extern nint MonitorFromWindow(nint hwnd, uint dwFlags);

    [DllImport("user32.dll")]
    private static extern nint SetThreadDpiAwarenessContext(nint dpiContext);

    [DllImport("user32.dll")]
    private static extern bool GetClientRect(nint hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    private static extern bool GetWindowRect(nint hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    private static extern bool IsWindow(nint hWnd);

    [DllImport("user32.dll")]
    private static extern bool DestroyWindow(nint hWnd);

    [DllImport("user32.dll")]
    private static extern nint GetDC(nint hWnd);

    [DllImport("user32.dll")]
    private static extern int ReleaseDC(nint hWnd, nint hDC);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern nint CreateWindowExW(
        uint dwExStyle,
        string lpClassName,
        string lpWindowName,
        uint dwStyle,
        int X,
        int Y,
        int nWidth,
        int nHeight,
        nint hWndParent,
        nint hMenu,
        nint hInstance,
        nint lpParam);

    [DllImport("gdi32.dll")]
    private static extern int SetDIBitsToDevice(
        nint hdc,
        int xDest,
        int yDest,
        uint w,
        uint h,
        int xSrc,
        int ySrc,
        uint StartScan,
        uint cLines,
        byte[] lpvBits,
        ref BITMAPINFOHEADER lpbmi,
        uint ColorUse);

    [DllImport("user32.dll")]
    private static extern bool SetWindowPos(nint hWnd, nint hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern bool GetMonitorInfoW(nint hMonitor, ref MONITORINFOEXW lpmi);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern bool EnumDisplaySettingsW(string? lpszDeviceName, int iModeNum, ref DEVMODEW lpDevMode);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int ChangeDisplaySettingsExW(
        string? lpszDeviceName,
        ref DEVMODEW lpDevMode,
        nint hwnd,
        uint dwflags,
        nint lParam);
}
