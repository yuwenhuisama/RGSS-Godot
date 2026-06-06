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
        var data = new SpriteData(state)
        {
            Viewport = viewportData,
            SrcRect = new RectData(state),
            Tone = new ToneData(state),
            Color = new ColorData(state),
        };

        GameRenderManager.Instance.RegisterSprite(data, viewportData);

        var obj = self.ToClass().NewObjectWithRData(data);
        obj["@viewport"] = viewport;
        obj["@bitmap"] = state.RbNil;
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
        if (bitmap.IsNil)
        {
            data.Bitmap = null;
            data.SrcRect = new RectData(state);
        }
        else
        {
            var bitmapData = bitmap.GetRDataObject<BitmapData>();
            data.Bitmap = bitmapData;
            data.SrcRect = new RectData(state)
            {
                X = 0,
                Y = 0,
                Width = bitmapData.Width,
                Height = bitmapData.Height,
            };
        }

        self["@bitmap"] = bitmap;
        return state.RbNil;
    }

    [RbInstanceMethod("src_rect")]
    public static RbValue GetSrcRect(RbState state, RbValue self)
    {
        var data = self.GetRDataObject<SpriteData>();
        var rect = data.SrcRect;
        if (rect is null)
            return Rect.CreateRect(state, 0, 0, GetSourceWidth(data), GetSourceHeight(data));

        return Rect.CreateRect(state, rect.X, rect.Y, rect.Width, rect.Height);
    }

    [RbInstanceMethod("src_rect=")]
    public static RbValue SetSrcRect(RbState state, RbValue self, RbValue rect)
    {
        var rectData = rect.GetRDataObject<RectData>();
        self.GetRDataObject<SpriteData>().SrcRect = new RectData(state)
        {
            X = rectData.X,
            Y = rectData.Y,
            Width = rectData.Width,
            Height = rectData.Height,
        };

        return state.RbNil;
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
        var tone = self.GetRDataObject<SpriteData>().Tone;
        return Tone.CreateTone(state,
            (tone?.Red ?? 0.0f) * 255.0f,
            (tone?.Green ?? 0.0f) * 255.0f,
            (tone?.Blue ?? 0.0f) * 255.0f,
            (tone?.Gray ?? 0.0f) * 255.0f);
    }

    [RbInstanceMethod("tone=")]
    public static RbValue SetTone(RbState state, RbValue self, RbValue tone)
    {
        self.GetRDataObject<SpriteData>().Tone = tone.GetRDataObject<ToneData>();
        return state.RbNil;
    }

    [RbInstanceMethod("color")]
    public static RbValue GetColor(RbState state, RbValue self)
    {
        var color = self.GetRDataObject<SpriteData>().Color;
        return Color.CreateColor(state,
            (color?.R ?? 0.0f) * 255.0f,
            (color?.G ?? 0.0f) * 255.0f,
            (color?.B ?? 0.0f) * 255.0f,
            (color?.A ?? 0.0f) * 255.0f);
    }

    [RbInstanceMethod("color=")]
    public static RbValue SetColor(RbState state, RbValue self, RbValue color)
    {
        self.GetRDataObject<SpriteData>().Color = color.GetRDataObject<ColorData>();
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
