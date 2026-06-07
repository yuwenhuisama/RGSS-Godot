using MRuby.Library.Language;
using MRuby.Library.Mapper;
using Godot;
using System;

namespace RGSSUnity.RubyClasses;

[RbModule("Graphics", "Unity")]
public static class Graphics
{
    public static bool Freezing { get; private set; }

    private static long frameCount;

    public static void Render()
    {
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
        // No-op on the C# side: the cooperative frame barrier lives in the Ruby
        // Graphics.update wrapper, and Graphics.wait is reimplemented Ruby-side as
        // `n.times { update }`. Kept as a binding so any direct Unity::Graphics.wait
        // call is harmless.
        _ = duration;
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
        // Start-only: kick off the brightness ramp to black. The Ruby Graphics.fadeout
        // wrapper drives the per-frame waiting via `n.times { update }`; this side only
        // owns the brightness animation state (advanced by GameRenderManager each frame).
        int frames = Math.Max(0, (int)duration.ToIntUnchecked());
        GameRenderManager.Instance.StartBrightnessFade(0.0f, frames);
        return state.RbNil;
    }

    [RbModuleMethod("fadein")]
    private static RbValue FadeIn(RbState state, RbValue self, RbValue duration)
    {
        // Start-only (see fadeout). Ramp brightness to full; Ruby wrapper does the waiting.
        int frames = Math.Max(0, (int)duration.ToIntUnchecked());
        GameRenderManager.Instance.StartBrightnessFade(1.0f, frames);
        return state.RbNil;
    }

    [RbModuleMethod("freeze")]
    private static RbValue Freeze(RbState state, RbValue self)
    {
        Freezing = true;
        GameRenderManager.Instance.FreezeScreen();
        return state.RbNil;
    }

    [RbModuleMethod("transition")]
    private static RbValue Transition(RbState state, RbValue self, RbValue duration, RbValue maskBitmap, RbValue vague)
    {
        Freezing = false;
        int frames = Math.Max(0, (int)duration.ToIntUnchecked());

        // No mask (nil filename): keep the Phase 1 brightness-ramp transition. After a
        // preceding fadeout the screen is black and this fades the new scene in; with no
        // fadeout (brightness already 1) it is an instant no-op.
        if (maskBitmap.IsNil)
        {
            GameRenderManager.Instance.StartBrightnessFade(1.0f, frames);
            return state.RbNil;
        }

        // Masked transition (e.g. battle entry): dissolve the frozen old screen into the
        // live new scene through the mask's red channel over `frames` frames.
        var maskData = maskBitmap.GetRDataObject<BitmapData>();
        if (maskData.Disposed || maskData.Image is null || maskData.Image.IsEmpty())
        {
            GameRenderManager.Instance.StartBrightnessFade(1.0f, frames);
            return state.RbNil;
        }

        var maskTexture = CreateOwnedTextureCopy(maskData.Image);
        int vagueValue = (int)vague.ToIntUnchecked();
        GameRenderManager.Instance.StartTransition(maskTexture, vagueValue, frames);
        return state.RbNil;
    }

    // Build an independent ImageTexture from the mask bitmap's image without mutating
    // the cached Bitmap (it may be reused). Duplicate, convert to Rgba8, then upload.
    private static ImageTexture CreateOwnedTextureCopy(Image source)
    {
        var copy = Image.CreateEmpty(source.GetWidth(), source.GetHeight(), false, source.GetFormat());
        copy.BlitRect(source, new Rect2I(0, 0, source.GetWidth(), source.GetHeight()), Vector2I.Zero);
        if (copy.GetFormat() != Image.Format.Rgba8)
            copy.Convert(Image.Format.Rgba8);
        return ImageTexture.CreateFromImage(copy);
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
