using System;
using MRuby.Library.Language;
using MRuby.Library.Mapper;

namespace RGSSUnity.RubyClasses;

[RbClass("Sprite", "Object", "Unity")]
public static class Sprite
{
    [RbClassMethod("new_with_viewport")]
    public static RbValue NewWithViewport(RbState state, RbValue self, RbValue viewport)
    {
        var viewportData = viewport.GetRDataObject<ViewportData>();
        var toneObj = Tone.CreateTone(state, 0.0f, 0.0f, 0.0f, 0.0f);
        var colorObj = Color.CreateColor(state, 0.0f, 0.0f, 0.0f, 0.0f);
        var srcRectObj = Rect.CreateRect(state, 0, 0, 0, 0);
        var data = new SpriteData(state)
        {
            Viewport = viewportData,
            SrcRect = srcRectObj.GetRDataObject<RectData>(),
            Tone = toneObj.GetRDataObject<ToneData>(),
            Color = colorObj.GetRDataObject<ColorData>(),
        };

        GameRenderManager.Instance.RegisterSprite(data, viewportData);

        var obj = self.ToClass().NewObjectWithRData(data);
        obj["@viewport"] = viewport;
        obj["@bitmap"] = state.RbNil;
        obj["@tone"] = toneObj;
        obj["@color"] = colorObj;
        obj["@src_rect"] = srcRectObj;
        return obj;
    }

    [RbInstanceMethod("dispose")]
    public static RbValue Dispose(RbState state, RbValue self)
    {
        var data = self.GetRDataObject<SpriteData>();
        if (data.Disposed)
            return state.RbNil;

        GameRenderManager.Instance.UnregisterSprite(data);
        data.Disposed = true;
        data.Bitmap = null;
        data.Viewport = null;
        data.Node = null;
        return state.RbNil;
    }

    [RbInstanceMethod("disposed?")]
    public static RbValue Disposed(RbState state, RbValue self)
        => self.GetRDataObject<SpriteData>().Disposed.ToValue(state);

    [RbInstanceMethod("flash")]
    public static RbValue Flash(RbState state, RbValue self, RbValue color, RbValue duration)
    {
        var data = self.GetRDataObject<SpriteData>();
        data.FlashDuration = Math.Max(0, (int)duration.ToIntUnchecked());
        data.FlashRemain = data.FlashDuration;
        data.FlashColor = color.IsNil ? null : color.GetRDataObject<ColorData>();
        return state.RbNil;
    }

    [RbInstanceMethod("update")]
    public static RbValue Update(RbState state, RbValue self)
    {
        var data = self.GetRDataObject<SpriteData>();

        if (data.FlashRemain > 0)
            --data.FlashRemain;
        else
        {
            data.FlashDuration = 0;
            data.FlashRemain = 0;
            data.FlashColor = null;
        }

        if (data.WaveAmp != 0.0f && Math.Abs(data.WaveLength) > float.Epsilon)
        {
            data.WavePhase += data.WaveSpeed / data.WaveLength;
            data.WavePhase %= 360.0f;
            if (data.WavePhase < 0.0f)
                data.WavePhase += 360.0f;
        }

        return state.RbNil;
    }

    [RbInstanceMethod("width")]
    public static RbValue Width(RbState state, RbValue self)
    {
        var data = self.GetRDataObject<SpriteData>();
        return GetSourceWidth(data).ToValue(state);
    }

    [RbInstanceMethod("height")]
    public static RbValue Height(RbState state, RbValue self)
    {
        var data = self.GetRDataObject<SpriteData>();
        return GetSourceHeight(data).ToValue(state);
    }

    [RbInstanceMethod("bitmap")]
    public static RbValue GetBitmap(RbState state, RbValue self) => self["@bitmap"];

    [RbInstanceMethod("bitmap=")]
    public static RbValue SetBitmap(RbState state, RbValue self, RbValue bitmap)
    {
        var data = self.GetRDataObject<SpriteData>();
        // Mutate the existing SrcRect in place (keeping it === the stored @src_rect
        // wrapper) so that a later `sprite.src_rect.set(...)` still hits live data.
        data.SrcRect ??= EnsureSrcRect(state, self);
        if (bitmap.IsNil)
        {
            data.Bitmap = null;
            data.SrcRect.X = 0;
            data.SrcRect.Y = 0;
            data.SrcRect.Width = 0;
            data.SrcRect.Height = 0;
        }
        else
        {
            var bitmapData = bitmap.GetRDataObject<BitmapData>();
            data.Bitmap = bitmapData;
            data.SrcRect.X = 0;
            data.SrcRect.Y = 0;
            data.SrcRect.Width = bitmapData.Width;
            data.SrcRect.Height = bitmapData.Height;
        }

        self["@bitmap"] = bitmap;
        return state.RbNil;
    }

    [RbInstanceMethod("src_rect")]
    public static RbValue GetSrcRect(RbState state, RbValue self)
    {
        // Return the stored Rect wrapper so RGSS3 `sprite.src_rect.set(...)`
        // (character/animation frame selection) mutates the live SpriteData.SrcRect.
        var stored = self["@src_rect"];
        if (!stored.IsNil)
            return stored;

        return EnsureSrcRectObj(state, self);
    }

    [RbInstanceMethod("src_rect=")]
    public static RbValue SetSrcRect(RbState state, RbValue self, RbValue rect)
    {
        var rectData = rect.GetRDataObject<RectData>();
        var data = self.GetRDataObject<SpriteData>();
        // Mutate the existing SrcRect in place rather than replacing the instance, so the
        // stored @src_rect wrapper stays bound to the live data.
        data.SrcRect ??= EnsureSrcRect(state, self);
        data.SrcRect.X = rectData.X;
        data.SrcRect.Y = rectData.Y;
        data.SrcRect.Width = rectData.Width;
        data.SrcRect.Height = rectData.Height;

        return state.RbNil;
    }

    // Ensures a SrcRect RectData exists AND a matching @src_rect wrapper is stored,
    // returning the RectData. Used to recover from any state where SrcRect is null.
    private static RectData EnsureSrcRect(RbState state, RbValue self)
        => EnsureSrcRectObj(state, self).GetRDataObject<RectData>();

    private static RbValue EnsureSrcRectObj(RbState state, RbValue self)
    {
        var stored = self["@src_rect"];
        if (!stored.IsNil)
            return stored;

        var data = self.GetRDataObject<SpriteData>();
        var srcRectObj = Rect.CreateRect(state,
            data.SrcRect?.X ?? 0, data.SrcRect?.Y ?? 0,
            data.SrcRect?.Width ?? GetSourceWidth(data), data.SrcRect?.Height ?? GetSourceHeight(data));
        data.SrcRect = srcRectObj.GetRDataObject<RectData>();
        self["@src_rect"] = srcRectObj;
        return srcRectObj;
    }

    [RbInstanceMethod("viewport")]
    public static RbValue GetViewport(RbState state, RbValue self) => self["@viewport"];

    [RbInstanceMethod("viewport=")]
    public static RbValue SetViewport(RbState state, RbValue self, RbValue viewport)
    {
        var data = self.GetRDataObject<SpriteData>();
        var viewportData = viewport.GetRDataObject<ViewportData>();
        GameRenderManager.Instance.RegisterSprite(data, viewportData);
        self["@viewport"] = viewport;
        return viewport;
    }

    [RbInstanceMethod("tone")]
    public static RbValue GetTone(RbState state, RbValue self)
    {
        // Return the stored Tone wrapper so RGSS3 `sprite.tone.set(...)` mutates the
        // live SpriteData.Tone the renderer reads (e.g. Spriteset map screen tinting).
        var stored = self["@tone"];
        if (!stored.IsNil)
            return stored;

        var data = self.GetRDataObject<SpriteData>();
        var toneObj = Tone.CreateTone(state,
            (data.Tone?.Red ?? 0.0f) * 255.0f,
            (data.Tone?.Green ?? 0.0f) * 255.0f,
            (data.Tone?.Blue ?? 0.0f) * 255.0f,
            (data.Tone?.Gray ?? 0.0f) * 255.0f);
        data.Tone = toneObj.GetRDataObject<ToneData>();
        self["@tone"] = toneObj;
        return toneObj;
    }

    [RbInstanceMethod("tone=")]
    public static RbValue SetTone(RbState state, RbValue self, RbValue tone)
    {
        self.GetRDataObject<SpriteData>().Tone = tone.GetRDataObject<ToneData>();
        self["@tone"] = tone;
        return state.RbNil;
    }

    [RbInstanceMethod("color")]
    public static RbValue GetColor(RbState state, RbValue self)
    {
        // Return the stored Color wrapper so RGSS3 `sprite.color.set(...)` (flash/fade
        // blending) mutates the live SpriteData.Color the renderer reads.
        var stored = self["@color"];
        if (!stored.IsNil)
            return stored;

        var data = self.GetRDataObject<SpriteData>();
        var colorObj = Color.CreateColor(state,
            (data.Color?.R ?? 0.0f) * 255.0f,
            (data.Color?.G ?? 0.0f) * 255.0f,
            (data.Color?.B ?? 0.0f) * 255.0f,
            (data.Color?.A ?? 0.0f) * 255.0f);
        data.Color = colorObj.GetRDataObject<ColorData>();
        self["@color"] = colorObj;
        return colorObj;
    }

    [RbInstanceMethod("color=")]
    public static RbValue SetColor(RbState state, RbValue self, RbValue color)
    {
        self.GetRDataObject<SpriteData>().Color = color.GetRDataObject<ColorData>();
        self["@color"] = color;
        return state.RbNil;
    }

    [RbInstanceMethod("visible")]
    public static RbValue GetVisible(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().Visible.ToValue(state);

    [RbInstanceMethod("visible=")]
    public static RbValue SetVisible(RbState state, RbValue self, RbValue visible)
    {
        self.GetRDataObject<SpriteData>().Visible = visible.IsTrue;
        return state.RbNil;
    }

    [RbInstanceMethod("x")]
    public static RbValue GetX(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().X.ToValue(state);

    [RbInstanceMethod("x=")]
    public static RbValue SetX(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().X = (int)value.ToIntUnchecked();
        return state.RbNil;
    }

    [RbInstanceMethod("y")]
    public static RbValue GetY(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().Y.ToValue(state);

    [RbInstanceMethod("y=")]
    public static RbValue SetY(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().Y = (int)value.ToIntUnchecked();
        return state.RbNil;
    }

    [RbInstanceMethod("z")]
    public static RbValue GetZ(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().Z.ToValue(state);

    [RbInstanceMethod("z=")]
    public static RbValue SetZ(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().Z = (int)value.ToIntUnchecked();
        return state.RbNil;
    }

    [RbInstanceMethod("ox")]
    public static RbValue GetOx(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().Ox.ToValue(state);

    [RbInstanceMethod("ox=")]
    public static RbValue SetOx(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().Ox = (int)value.ToIntUnchecked();
        return state.RbNil;
    }

    [RbInstanceMethod("oy")]
    public static RbValue GetOy(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().Oy.ToValue(state);

    [RbInstanceMethod("oy=")]
    public static RbValue SetOy(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().Oy = (int)value.ToIntUnchecked();
        return state.RbNil;
    }

    [RbInstanceMethod("zoom_x")]
    public static RbValue GetZoomX(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().ZoomX.ToValue(state);

    [RbInstanceMethod("zoom_x=")]
    public static RbValue SetZoomX(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().ZoomX = ToFloat(value);
        return state.RbNil;
    }

    [RbInstanceMethod("zoom_y")]
    public static RbValue GetZoomY(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().ZoomY.ToValue(state);

    [RbInstanceMethod("zoom_y=")]
    public static RbValue SetZoomY(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().ZoomY = ToFloat(value);
        return state.RbNil;
    }

    [RbInstanceMethod("angle")]
    public static RbValue GetAngle(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().Angle.ToValue(state);

    [RbInstanceMethod("angle=")]
    public static RbValue SetAngle(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().Angle = ToFloat(value);
        return state.RbNil;
    }

    [RbInstanceMethod("mirror")]
    public static RbValue GetMirror(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().Mirror.ToValue(state);

    [RbInstanceMethod("mirror=")]
    public static RbValue SetMirror(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().Mirror = value.IsTrue;
        return state.RbNil;
    }

    [RbInstanceMethod("opacity")]
    public static RbValue GetOpacity(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().Opacity.ToValue(state);

    [RbInstanceMethod("opacity=")]
    public static RbValue SetOpacity(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().Opacity = Math.Clamp((int)value.ToIntUnchecked(), 0, 255);
        return state.RbNil;
    }

    [RbInstanceMethod("blend_type")]
    public static RbValue GetBlendType(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().BlendType.ToValue(state);

    [RbInstanceMethod("blend_type=")]
    public static RbValue SetBlendType(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().BlendType = Math.Clamp((int)value.ToIntUnchecked(), 0, 2);
        return state.RbNil;
    }

    [RbInstanceMethod("bush_depth")]
    public static RbValue GetBushDepth(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().BushDepth.ToValue(state);

    [RbInstanceMethod("bush_depth=")]
    public static RbValue SetBushDepth(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().BushDepth = ToFloat(value);
        return state.RbNil;
    }

    [RbInstanceMethod("bush_opacity")]
    public static RbValue GetBushOpacity(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().BushOpacity.ToValue(state);

    [RbInstanceMethod("bush_opacity=")]
    public static RbValue SetBushOpacity(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().BushOpacity = Math.Clamp((int)value.ToIntUnchecked(), 0, 255);
        return state.RbNil;
    }

    [RbInstanceMethod("wave_amp")]
    public static RbValue GetWaveAmp(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().WaveAmp.ToValue(state);

    [RbInstanceMethod("wave_amp=")]
    public static RbValue SetWaveAmp(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().WaveAmp = ToFloat(value);
        return state.RbNil;
    }

    [RbInstanceMethod("wave_length")]
    public static RbValue GetWaveLength(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().WaveLength.ToValue(state);

    [RbInstanceMethod("wave_length=")]
    public static RbValue SetWaveLength(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().WaveLength = ToFloat(value);
        return state.RbNil;
    }

    [RbInstanceMethod("wave_speed")]
    public static RbValue GetWaveSpeed(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().WaveSpeed.ToValue(state);

    [RbInstanceMethod("wave_speed=")]
    public static RbValue SetWaveSpeed(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().WaveSpeed = ToFloat(value);
        return state.RbNil;
    }

    [RbInstanceMethod("wave_phase")]
    public static RbValue GetWavePhase(RbState state, RbValue self) => self.GetRDataObject<SpriteData>().WavePhase.ToValue(state);

    [RbInstanceMethod("wave_phase=")]
    public static RbValue SetWavePhase(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<SpriteData>().WavePhase = ToFloat(value);
        return state.RbNil;
    }

    private static float ToFloat(RbValue value)
        => value.IsFloat ? Convert.ToSingle(value.ToFloatUnchecked()) : Convert.ToSingle(value.ToIntUnchecked());

    private static int GetSourceWidth(SpriteData data)
        => data.SrcRect?.Width > 0 ? data.SrcRect.Width : data.Bitmap?.Width ?? 0;

    private static int GetSourceHeight(SpriteData data)
        => data.SrcRect?.Height > 0 ? data.SrcRect.Height : data.Bitmap?.Height ?? 0;
}
