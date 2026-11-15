using System;
using System.Collections.Generic;
using Godot;

namespace RGSSUnity;

public partial class GameSettings : Node
{
    private const string SettingsPath = "user://rgss_settings.cfg";
    private static readonly Key[] KeyboardKeys = [Key.Space, Key.Enter, Key.Escape, Key.Kp0, Key.Shift,
        Key.Z, Key.X, Key.C, Key.V, Key.B, Key.A, Key.S, Key.D, Key.Q, Key.W];
    private static readonly string[] Actions = ["-", "A", "B", "C", "X", "Y", "Z", "L", "R"];
    private static readonly int[] DefaultKeys = [3, 3, 2, 2, 1, 3, 2, 0, 0, 0, 4, 5, 6, 7, 8];
    private static readonly int[] DefaultPad = [1, 2, 3, 4, 5, 6, 7, 8, 0, 0];
    private readonly ConfigFile config = new();
    private AcceptDialog? dialog;
    private string originalTitle = string.Empty;
    private CanvasLayer? layer;
    private bool displayFps;
    private double elapsed;
    private bool fullscreenRequested;
    private bool nativeFullscreenActive;
    private bool suspendedForFocusLoss;
    private Vector2I savedWindowedSize;
    private Vector2I savedWindowedPosition;
    private bool hasSavedWindowedGeometry;
    private Vector2I lastAttachedLogicalSize;
    private Vector2I lastAttachedPhysicalSize;
    private int attachKeepAliveFrames;
    private int focusLossGraceFrames;

    public bool IsFullscreenRequested => this.fullscreenRequested;
    public bool IsNativeFullscreenActive => this.nativeFullscreenActive;

    public override void _Ready()
    {
        var result = this.config.Load(SettingsPath);
        if (result != Error.Ok && result != Error.FileNotFound)
            GD.PrintErr($"Cannot load RGSS settings: {result}");
        Apply();
        this.layer = new CanvasLayer { Layer = 1000 };
        AddChild(this.layer);
        this.originalTitle = GetWindow().Title;
    }

    public override void _ExitTree()
    {
        WindowsDisplayMode.DestroyPhysicalPresenter();
        RestoreDisplayModeIfActive();
    }

    public override void _Notification(int what)
    {
        if (what == NotificationWMCloseRequest)
        {
            WindowsDisplayMode.DestroyPhysicalPresenter();
            RestoreDisplayModeIfActive();
            return;
        }

        if (what == NotificationWMWindowFocusOut || what == NotificationApplicationFocusOut)
        {
            if (this.fullscreenRequested && this.nativeFullscreenActive && !IsPropertiesDialogActive() && this.focusLossGraceFrames <= 0)
            {
                var hwnd = WindowsDisplayMode.IsSupportedHost && !string.Equals(DisplayServer.GetName(), "headless", StringComparison.OrdinalIgnoreCase)
                    ? (nint)DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle)
                    : nint.Zero;
                WindowsDisplayMode.DestroyPhysicalPresenter();
                RestoreDisplayModeIfActive();
                if (hwnd != nint.Zero)
                    WindowsDisplayMode.ClearTopmostFlag(hwnd);
                this.suspendedForFocusLoss = true;
            }
            return;
        }

        if (what == NotificationWMWindowFocusIn || what == NotificationApplicationFocusIn)
        {
            if (this.fullscreenRequested && this.suspendedForFocusLoss)
            {
                this.suspendedForFocusLoss = false;
                SetFullscreen(true);
            }
            return;
        }

        if ((what == NotificationWMSizeChanged || what == NotificationWMDpiChange) && this.fullscreenRequested)
        {
            this.attachKeepAliveFrames = 8;
            SyncFullscreenViewportCentering(force: true);
        }
    }

    private int Assignment(string section, int index, int defaultValue)
        => this.config.GetValue(section, index.ToString(), defaultValue).AsInt32();

    private bool Setting(string key, bool defaultValue)
        => this.config.GetValue("general", key, defaultValue).AsBool();

    private void Apply()
    {
        GameInputManager.RegisterActions();
        foreach (var action in Actions)
            if (action != "-") InputMap.ActionEraseEvents("rgss_" + action.ToLowerInvariant());
        for (var index = 0; index < KeyboardKeys.Length; index++)
        {
            var action = Assignment("keyboard", index, DefaultKeys[index]);
            if (action > 0 && action < Actions.Length)
                InputMap.ActionAddEvent("rgss_" + Actions[action].ToLowerInvariant(), new InputEventKey { Keycode = KeyboardKeys[index] });
        }
        for (var index = 0; index < DefaultPad.Length; index++)
        {
            var action = Assignment("gamepad", index, DefaultPad[index]);
            if (action > 0 && action < Actions.Length)
                InputMap.ActionAddEvent("rgss_" + Actions[action].ToLowerInvariant(), new InputEventJoypadButton { ButtonIndex = (JoyButton)index });
        }
        InputMap.ActionAddEvent("rgss_l", new InputEventKey { Keycode = Key.Pageup });
        InputMap.ActionAddEvent("rgss_r", new InputEventKey { Keycode = Key.Pagedown });
        SetFullscreen(Setting("fullscreen", false));
        DisplayServer.WindowSetVsyncMode(Setting("vsync", true) ? DisplayServer.VSyncMode.Enabled : DisplayServer.VSyncMode.Disabled);
        GameAudioManager.Instance.SetEnabled(Setting("music", true), Setting("sound", true));
    }

    public bool SetFullscreen(bool enabled)
    {
        var window = GetWindow();
        if (window is null)
            return false;

        if (!enabled)
        {
            this.fullscreenRequested = false;
            this.suspendedForFocusLoss = false;
            var wasFullscreen = this.nativeFullscreenActive || IsWindowModeFullscreen();
            var hwnd = WindowsDisplayMode.IsSupportedHost && !string.Equals(DisplayServer.GetName(), "headless", StringComparison.OrdinalIgnoreCase)
                ? (nint)DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle)
                : nint.Zero;
            WindowsDisplayMode.DestroyPhysicalPresenter();
            RestoreDisplayModeIfActive();
            if (hwnd != nint.Zero)
                WindowsDisplayMode.ClearTopmostFlag(hwnd);
            if (wasFullscreen || DisplayServer.WindowGetMode() != DisplayServer.WindowMode.Windowed)
                DisplayServer.WindowSetMode(DisplayServer.WindowMode.Windowed);
            if (wasFullscreen && this.hasSavedWindowedGeometry)
            {
                if (this.savedWindowedSize.X > 0 && this.savedWindowedSize.Y > 0)
                    window.Size = this.savedWindowedSize;
                if (hwnd != nint.Zero)
                    WindowsDisplayMode.MoveWindowWin32(hwnd, this.savedWindowedPosition.X, this.savedWindowedPosition.Y);
                else
                    window.Position = this.savedWindowedPosition;
            }
            this.lastAttachedLogicalSize = Vector2I.Zero;
            this.lastAttachedPhysicalSize = Vector2I.Zero;
            this.attachKeepAliveFrames = 0;
            this.focusLossGraceFrames = 0;
            SyncWindowedViewportPresentation(window);
            return true;
        }

        var displayName = DisplayServer.GetName();
        if (!this.fullscreenRequested && !IsWindowModeFullscreen())
        {
            this.savedWindowedSize = window.Size;
            var curHwnd = WindowsDisplayMode.IsSupportedHost && !string.Equals(displayName, "headless", StringComparison.OrdinalIgnoreCase)
                ? (nint)DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle)
                : nint.Zero;
            this.savedWindowedPosition = curHwnd != nint.Zero
                ? WindowsDisplayMode.GetWindowPositionWin32(curHwnd)
                : window.Position;
            this.hasSavedWindowedGeometry = true;
        }

        if (string.Equals(displayName, "headless", StringComparison.OrdinalIgnoreCase))
        {
            this.fullscreenRequested = true;
            this.suspendedForFocusLoss = false;
            DisplayServer.WindowSetMode(DisplayServer.WindowMode.Fullscreen);
            return true;
        }

        if (WindowsDisplayMode.IsSupportedHost)
        {
            var hwnd = (nint)DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle);
            var logical = ResolveLogicalSize(window);
            var switchResult = WindowsDisplayMode.EnterFullscreenMode(hwnd, logical.X, logical.Y);
            if (!switchResult.Success)
            {
                GD.PrintErr($"FULLSCREEN_MODE_ERROR:{switchResult.Message}");
                this.fullscreenRequested = false;
                this.nativeFullscreenActive = false;
                return false;
            }

            this.fullscreenRequested = true;
            this.nativeFullscreenActive = true;
            this.suspendedForFocusLoss = false;
            this.attachKeepAliveFrames = 12;
            this.focusLossGraceFrames = 16;
            DisplayServer.WindowSetMode(DisplayServer.WindowMode.ExclusiveFullscreen);
            SyncFullscreenWindowGeometry(window, hwnd, switchResult.TargetMode.DeviceName, switchResult.TargetMode.Width, switchResult.TargetMode.Height);
            SyncFullscreenViewportCentering(force: true);
            return true;
        }

        this.fullscreenRequested = true;
        this.suspendedForFocusLoss = false;
        DisplayServer.WindowSetMode(DisplayServer.WindowMode.ExclusiveFullscreen);
        SyncFullscreenViewportCentering(force: true);
        return true;
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is not InputEventKey { Pressed: true, Echo: false } key)
            return;
        if (key.Keycode == Key.F1)
        {
            OpenProperties();
            GetViewport().SetInputAsHandled();
        }
        else if (key.Keycode == Key.F2)
        {
            this.displayFps = !this.displayFps;
            GetWindow().Title = this.displayFps ? $"{this.originalTitle} - {Engine.GetFramesPerSecond()} FPS" : this.originalTitle;
            GetViewport().SetInputAsHandled();
        }
        else if (key.Keycode == Key.Enter && key.AltPressed)
        {
            var currentlyFullscreen = this.fullscreenRequested || IsWindowModeFullscreen();
            SetFullscreen(!currentlyFullscreen);
            GetViewport().SetInputAsHandled();
        }
    }

    public override void _Process(double delta)
    {
        this.elapsed += delta;
        if (this.displayFps && this.elapsed >= 0.25)
        {
            GetWindow().Title = $"{this.originalTitle} - {Engine.GetFramesPerSecond()} FPS";
            this.elapsed = 0;
        }
        if (this.focusLossGraceFrames > 0)
            this.focusLossGraceFrames--;
        if (this.fullscreenRequested && !this.suspendedForFocusLoss)
            SyncFullscreenViewportCentering(force: false);
    }

    private static bool IsWindowModeFullscreen()
    {
        var mode = DisplayServer.WindowGetMode();
        return mode == DisplayServer.WindowMode.Fullscreen || mode == DisplayServer.WindowMode.ExclusiveFullscreen;
    }

    private bool IsPropertiesDialogActive()
        => this.dialog is not null && GodotObject.IsInstanceValid(this.dialog) && this.dialog.Visible;

    private void RestoreDisplayModeIfActive()
    {
        if (!this.nativeFullscreenActive && !WindowsDisplayMode.IsActive)
            return;

        if (!WindowsDisplayMode.RestorePreviousMode(out _, out var message))
            GD.PrintErr($"FULLSCREEN_RESTORE_ERROR:{message}");
        else
            this.nativeFullscreenActive = false;
    }

    private static Vector2I ResolveLogicalSize(Window window)
    {
        if (window.ContentScaleSize.X > 0 && window.ContentScaleSize.Y > 0)
            return window.ContentScaleSize;

        var visible = window.GetVisibleRect().Size;
        if (visible.X > 0 && visible.Y > 0)
            return new Vector2I((int)MathF.Round(visible.X), (int)MathF.Round(visible.Y));

        return new Vector2I(544, 416);
    }

    private static Vector2I SyncFullscreenWindowGeometry(Window window, nint hwnd, string? deviceName, int targetWidth, int targetHeight)
    {
        if (targetWidth <= 0 || targetHeight <= 0)
            return Vector2I.Zero;

        var windowRect = new Rect2I(0, 0, targetWidth, targetHeight);
        if (WindowsDisplayMode.TryGetLogicalMonitorRect(deviceName, hwnd, out var logicalMonitorRect)
            && logicalMonitorRect.Size.X > 0
            && logicalMonitorRect.Size.Y > 0)
        {
            windowRect = logicalMonitorRect;
        }

        WindowsDisplayMode.EnforceTopmostFullscreenRect(
            hwnd,
            windowRect.Position.X,
            windowRect.Position.Y,
            windowRect.Size.X,
            windowRect.Size.Y);
        if (window.Size != windowRect.Size)
            window.Size = windowRect.Size;
        return windowRect.Size;
    }

    private void SyncFullscreenViewportCentering(bool force)
    {
        if (string.Equals(DisplayServer.GetName(), "headless", StringComparison.OrdinalIgnoreCase))
            return;

        var window = GetWindow();
        if (window is null)
            return;

        var logical = ResolveLogicalSize(window);
        var swapchainSize = DisplayServer.WindowGetSize();
        var hwnd = WindowsDisplayMode.IsSupportedHost
            ? (nint)DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle)
            : nint.Zero;
        var deviceName = WindowsDisplayMode.ActiveDeviceName
            ?? (hwnd != nint.Zero ? WindowsDisplayMode.ResolveMonitorDeviceName(hwnd) : null);
            if (this.nativeFullscreenActive && WindowsDisplayMode.TryGetCurrentMode(deviceName, out var modeSnapshot)
            && modeSnapshot.Width > 0 && modeSnapshot.Height > 0)
        {
            if (logical != this.lastAttachedLogicalSize && this.lastAttachedLogicalSize != Vector2I.Zero)
            {
                var resizeSwitch = WindowsDisplayMode.EnterFullscreenMode(hwnd, logical.X, logical.Y);
                if (resizeSwitch.Success)
                {
                    modeSnapshot = resizeSwitch.TargetMode;
                    this.attachKeepAliveFrames = 8;
                    this.focusLossGraceFrames = 8;
                }
            }

            var physicalTarget = new Vector2I(modeSnapshot.Width, modeSnapshot.Height);
            var expectedLogicalRect = WindowsDisplayMode.TryGetLogicalMonitorRect(modeSnapshot.DeviceName, hwnd, out var monRect)
                && monRect.Size.X > 0 && monRect.Size.Y > 0
                ? monRect.Size
                : physicalTarget;
            var actualPhysicalClient = hwnd != nint.Zero ? WindowsDisplayMode.GetClientSizeWin32(hwnd) : physicalTarget;
            if (window.Size != expectedLogicalRect || actualPhysicalClient != physicalTarget || force)
            {
                swapchainSize = SyncFullscreenWindowGeometry(window, hwnd, modeSnapshot.DeviceName, physicalTarget.X, physicalTarget.Y);
                force = true;
            }
            else
            {
                swapchainSize = expectedLogicalRect;
            }

            // When Windows System-DPI virtualizes the main window (e.g. 150% -> 960x720 swapchain on a 640x480 mode),
            // DWM bilinear-downscales the main HWND. Present through a Per-Monitor-V2 native Win32 popup HWND
            // blitting the exact 1:1 logical RGBA frame centered in physical 640x480 with zero filtering.
            if (swapchainSize != physicalTarget && !IsPropertiesDialogActive())
            {
                PresentExactPhysicalFrame(window, hwnd, modeSnapshot.DeviceName, physicalTarget, logical);
                this.lastAttachedLogicalSize = logical;
                this.lastAttachedPhysicalSize = physicalTarget;
                if (this.attachKeepAliveFrames > 0)
                    this.attachKeepAliveFrames--;
                return;
            }

            WindowsDisplayMode.DestroyPhysicalPresenter();

            var clampedPhysW = Math.Min(logical.X, physicalTarget.X);
            var clampedPhysH = Math.Min(logical.Y, physicalTarget.Y);
            var physOffsetX = (physicalTarget.X - clampedPhysW) / 2;
            var physOffsetY = (physicalTarget.Y - clampedPhysH) / 2;
            var mappedRect = new Rect2(physOffsetX, physOffsetY, clampedPhysW, clampedPhysH);

            if (!force
                && this.attachKeepAliveFrames <= 0
                && logical == this.lastAttachedLogicalSize
                && swapchainSize == this.lastAttachedPhysicalSize)
            {
                return;
            }

            if (this.attachKeepAliveFrames > 0)
                this.attachKeepAliveFrames--;

            RenderingServer.ViewportAttachToScreen(window.GetViewportRid(), mappedRect, 0);
            this.lastAttachedLogicalSize = logical;
            this.lastAttachedPhysicalSize = swapchainSize;
            return;
        }

        if (swapchainSize.X <= 0 || swapchainSize.Y <= 0)
            return;

        var clampedWidth = Math.Min(logical.X, swapchainSize.X);
        var clampedHeight = Math.Min(logical.Y, swapchainSize.Y);
        var offsetX = (swapchainSize.X - clampedWidth) / 2;
        var offsetY = (swapchainSize.Y - clampedHeight) / 2;
        var attachRect = new Rect2(offsetX, offsetY, clampedWidth, clampedHeight);
        if (!force
            && !IsPropertiesDialogActive()
            && this.attachKeepAliveFrames <= 0
            && logical == this.lastAttachedLogicalSize
            && swapchainSize == this.lastAttachedPhysicalSize)
        {
            return;
        }

        if (this.attachKeepAliveFrames > 0)
            this.attachKeepAliveFrames--;

        RenderingServer.ViewportAttachToScreen(window.GetViewportRid(), attachRect, 0);
        this.lastAttachedLogicalSize = logical;
        this.lastAttachedPhysicalSize = swapchainSize;
    }

    private static void PresentExactPhysicalFrame(
        Window rootWindow,
        nint rootHwnd,
        string? deviceName,
        Vector2I physicalTarget,
        Vector2I logicalSize)
    {
        using var img = rootWindow.GetTexture()?.GetImage();
        if (img is null || img.IsEmpty())
            return;

        if (img.GetFormat() != Image.Format.Rgba8)
            img.Convert(Image.Format.Rgba8);

        var rgba = img.GetData();
        WindowsDisplayMode.PresentPhysicalCenteredRgba(
            rootHwnd,
            deviceName,
            physicalTarget.X,
            physicalTarget.Y,
            img.GetWidth(),
            img.GetHeight(),
            logicalSize.X,
            logicalSize.Y,
            rgba);
    }

    private static void SyncWindowedViewportPresentation(Window window)
    {
        if (string.Equals(DisplayServer.GetName(), "headless", StringComparison.OrdinalIgnoreCase))
            return;

        var scaleSize = window.ContentScaleSize;
        if (scaleSize.X > 0 && scaleSize.Y > 0)
            window.ContentScaleSize = scaleSize;
    }

    private void OpenProperties()
    {
        if (this.nativeFullscreenActive)
        {
            WindowsDisplayMode.DestroyPhysicalPresenter();
        }
        if (this.dialog is not null)
        {
            this.dialog.PopupCentered();
            return;
        }
        this.dialog = new AcceptDialog { Title = "Game Properties", MinSize = new Vector2I(480, 360), Exclusive = true };
        this.dialog.AddCancelButton("Cancel");
        this.layer!.AddChild(this.dialog);
        var tabs = new TabContainer { OffsetLeft = 12, OffsetTop = 12, OffsetRight = 468, OffsetBottom = 304 };
        this.dialog.AddChild(tabs);
        var general = new VBoxContainer { Name = "通常" };
        tabs.AddChild(general);
        var controls = new Dictionary<string, CheckBox>();
        foreach (var (key, title, defaultValue) in new[] { ("fullscreen", "全屏启动", false), ("vsync", "垂直同步", true), ("music", "播放音乐", true), ("sound", "播放声音", true) })
        {
            var control = new CheckBox { Text = title, ButtonPressed = Setting(key, defaultValue) };
            controls.Add(key, control);
            general.AddChild(control);
        }
        var pad = BuildMappings(tabs, "手柄", "gamepad", DefaultPad, index => $"Button {index + 1}");
        var keyboard = BuildMappings(tabs, "键盘", "keyboard", DefaultKeys, index => OS.GetKeycodeString(KeyboardKeys[index]));
        this.dialog.Confirmed += () =>
        {
            foreach (var (key, control) in controls) this.config.SetValue("general", key, control.ButtonPressed);
            for (var i = 0; i < pad.Count; i++) this.config.SetValue("gamepad", i.ToString(), pad[i].Selected);
            for (var i = 0; i < keyboard.Count; i++) this.config.SetValue("keyboard", i.ToString(), keyboard[i].Selected);
            var error = this.config.Save(SettingsPath);
            if (error != Error.Ok) GD.PrintErr($"Cannot save RGSS settings: {error}");
            Apply();
            CloseProperties();
        };
        this.dialog.Canceled += CloseProperties;
        this.dialog.CloseRequested += CloseProperties;
        this.dialog.PopupCentered();
    }

    private List<OptionButton> BuildMappings(TabContainer tabs, string title, string section, int[] defaults, Func<int, string> label)
    {
        var page = new VBoxContainer { Name = title };
        tabs.AddChild(page);
        var scroll = new ScrollContainer { SizeFlagsVertical = Control.SizeFlags.ExpandFill };
        page.AddChild(scroll);
        var grid = new GridContainer { Columns = 4, SizeFlagsHorizontal = Control.SizeFlags.ExpandFill };
        scroll.AddChild(grid);
        var choices = new List<OptionButton>();
        for (var index = 0; index < defaults.Length; index++)
        {
            grid.AddChild(new Label { Text = label(index) });
            var choice = new OptionButton { CustomMinimumSize = new Vector2(80, 0) };
            foreach (var action in Actions) choice.AddItem(action);
            choice.Select(Assignment(section, index, defaults[index]));
            grid.AddChild(choice);
            choices.Add(choice);
        }
        var reset = new Button { Text = "重置(R)" };
        reset.Pressed += () => { for (var index = 0; index < choices.Count; index++) choices[index].Select(defaults[index]); };
        page.AddChild(reset);
        return choices;
    }

    private void CloseProperties()
    {
        this.dialog?.QueueFree();
        this.dialog = null;
    }
}
