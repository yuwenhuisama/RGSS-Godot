using MRuby.Library.Language;
using MRuby.Library.Mapper;
using Godot;
using System;

namespace RGSSUnity.RubyClasses;

[RbModule("Graphics", "Unity")]
public static class Graphics
{
    public static int WaitCount { get; set; }
    public static bool Freezing { get; private set; }

    private static long frameCount;

    public static void Render()
    {
        if (WaitCount > 0)
            --WaitCount;

        ++frameCount;
    }

    [RbModuleMethod("update")]
    private static RbValue Update(RbState state, RbValue self)
    {
        Freezing = false;
        Render();
        return state.RbNil;
    }

    [RbModuleMethod("wait")]
    private static RbValue Wait(RbState state, RbValue self, RbValue duration)
    {
        WaitCount = Math.Max(0, (int)duration.ToIntUnchecked());
        return state.RbNil;
    }

    [RbModuleMethod("frame_rate")]
    private static RbValue GetFrameRate(RbState state, RbValue self)
        => ((long)Engine.MaxFps).ToValue(state);

    [RbModuleMethod("frame_rate=")]
    private static RbValue SetFrameRate(RbState state, RbValue self, RbValue value)
    {
        Engine.MaxFps = Math.Max(1, (int)value.ToIntUnchecked());
        return state.RbNil;
    }

    [RbModuleMethod("frame_count")]
    private static RbValue GetFrameCount(RbState state, RbValue self)
        => frameCount.ToValue(state);

    [RbModuleMethod("frame_count=")]
    private static RbValue SetFrameCount(RbState state, RbValue self, RbValue value)
    {
        frameCount = value.ToIntUnchecked();
        return state.RbNil;
    }

    [RbModuleMethod("frame_reset")]
    private static RbValue FrameReset(RbState state, RbValue self)
    {
        frameCount = 0;
        return state.RbNil;
    }

    [RbModuleMethod("brightness")]
    private static RbValue GetBrightness(RbState state, RbValue self)
        => ((long)Math.Clamp((int)MathF.Round(GameRenderManager.Instance.GetGraphicsBrightness() * 255.0f), 0, 255)).ToValue(state);

    [RbModuleMethod("brightness=")]
    private static RbValue SetBrightness(RbState state, RbValue self, RbValue value)
    {
        GameRenderManager.Instance.SetGraphicsBrightnessImmediate(Math.Clamp((int)value.ToIntUnchecked(), 0, 255) / 255.0f);
        return state.RbNil;
    }

    [RbModuleMethod("fadeout")]
    private static RbValue FadeOut(RbState state, RbValue self, RbValue duration)
    {
        int frames = Math.Max(0, (int)duration.ToIntUnchecked());
        GameRenderManager.Instance.StartBrightnessFade(0.0f, frames);
        WaitCount = frames;
        return state.RbNil;
    }

    [RbModuleMethod("fadein")]
    private static RbValue FadeIn(RbState state, RbValue self, RbValue duration)
    {
        int frames = Math.Max(0, (int)duration.ToIntUnchecked());
        GameRenderManager.Instance.StartBrightnessFade(1.0f, frames);
        WaitCount = frames;
        return state.RbNil;
    }

    [RbModuleMethod("freeze")]
    private static RbValue Freeze(RbState state, RbValue self)
    {
        Freezing = true;
        return state.RbNil;
    }

    [RbModuleMethod("transition")]
    private static RbValue Transition(RbState state, RbValue self, RbValue duration, RbValue filename, RbValue vague)
    {
        // Phase 1: brightness-ramp transition. After a preceding fadeout the screen is
        // black (brightness 0) and the new scene is already built, so ramping 0->1 fades
        // the new scene in from black. With no preceding fadeout (brightness already 1)
        // this is an instant no-op, preserving current behavior for same-brightness
        // (e.g. menu) changes. `filename`/`vague` (masked crossfade) are Phase 2.
        Freezing = false;
        int frames = Math.Max(0, (int)duration.ToIntUnchecked());
        GameRenderManager.Instance.StartBrightnessFade(1.0f, frames);
        WaitCount = frames;
        return state.RbNil;
    }

    [RbModuleMethod("resize_screen")]
    private static RbValue ResizeScreen(RbState state, RbValue self, RbValue width, RbValue height)
    {
        DisplayServer.WindowSetSize(new Vector2I((int)width.ToIntUnchecked(), (int)height.ToIntUnchecked()));
        return state.RbNil;
    }

    [RbModuleMethod("width")]
    private static RbValue Width(RbState state, RbValue self)
        => ((long)GetRenderSize().X).ToValue(state);

    [RbModuleMethod("height")]
    private static RbValue Height(RbState state, RbValue self)
        => ((long)GetRenderSize().Y).ToValue(state);

    [RbModuleMethod("snap_to_bitmap")]
    private static RbValue SnapToBitmap(RbState state, RbValue self)
    {
        var size = GetRenderSize();
        return Bitmap.NewWithWidthAndHeight(state, self, ((long)Math.Max(1, (int)size.X)).ToValue(state), ((long)Math.Max(1, (int)size.Y)).ToValue(state));
    }

    [RbModuleMethod("play_movie")]
    private static RbValue PlayMovie(RbState state, RbValue self, RbValue filename)
        => state.RbNil;

    private static Vector2 GetRenderSize()
    {
        if (GlobalConfig.Instance.LegacyMode)
            return new Vector2(GlobalConfig.Instance.LegacyModeWidth, GlobalConfig.Instance.LegacyModeHeight);

        var root = Engine.GetMainLoop() is SceneTree tree ? tree.Root : null;
        if (root is not null)
            return root.GetVisibleRect().Size;

        return new Vector2(544, 416);
    }
}
