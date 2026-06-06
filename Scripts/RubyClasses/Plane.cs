using System;
using MRuby.Library.Language;
using MRuby.Library.Mapper;

namespace RGSSUnity.RubyClasses;

[RbClass("Plane", "Object", "Unity")]
public static class Plane
{
    [RbClassMethod("new_with_viewport")]
    public static RbValue NewWithViewport(RbState state, RbValue self, RbValue viewport)
    {
        var viewportData = viewport.GetRDataObject<ViewportData>();
        var data = new PlaneData(state)
        {
            Viewport = viewportData,
            Tone = new ToneData(state),
            Color = new ColorData(state),
        };

        GameRenderManager.Instance.RegisterPlane(data, viewportData);

        var obj = self.ToClass().NewObjectWithRData(data);
        obj["@viewport"] = viewport;
        obj["@bitmap"] = state.RbNil;
        return obj;
    }

    [RbInstanceMethod("dispose")]
    public static RbValue Dispose(RbState state, RbValue self)
    {
        var data = self.GetRDataObject<PlaneData>();
        if (data.Disposed)
            return state.RbNil;

        GameRenderManager.Instance.UnregisterPlane(data);
        data.Disposed = true;
        data.Bitmap = null;
        data.Viewport = null;
        data.Node = null;
        return state.RbNil;
    }

    [RbInstanceMethod("disposed?")]
    public static RbValue Disposed(RbState state, RbValue self)
        => self.GetRDataObject<PlaneData>().Disposed.ToValue(state);

    [RbInstanceMethod("bitmap")]
    public static RbValue GetBitmap(RbState state, RbValue self) => self["@bitmap"];

    [RbInstanceMethod("bitmap=")]
    public static RbValue SetBitmap(RbState state, RbValue self, RbValue bitmap)
    {
        var data = self.GetRDataObject<PlaneData>();
        data.Bitmap = bitmap.IsNil ? null : bitmap.GetRDataObject<BitmapData>();
        self["@bitmap"] = bitmap;
        return state.RbNil;
    }

    [RbInstanceMethod("viewport")]
    public static RbValue GetViewport(RbState state, RbValue self) => self["@viewport"];

    [RbInstanceMethod("viewport=")]
    public static RbValue SetViewport(RbState state, RbValue self, RbValue viewport)
    {
        var data = self.GetRDataObject<PlaneData>();
        var viewportData = viewport.GetRDataObject<ViewportData>();
        GameRenderManager.Instance.RegisterPlane(data, viewportData);
        self["@viewport"] = viewport;
        return viewport;
    }

    [RbInstanceMethod("tone")]
    public static RbValue GetTone(RbState state, RbValue self)
    {
        var tone = self.GetRDataObject<PlaneData>().Tone;
        return Tone.CreateTone(state,
            (tone?.Red ?? 0.0f) * 255.0f,
            (tone?.Green ?? 0.0f) * 255.0f,
            (tone?.Blue ?? 0.0f) * 255.0f,
            (tone?.Gray ?? 0.0f) * 255.0f);
    }

    [RbInstanceMethod("tone=")]
    public static RbValue SetTone(RbState state, RbValue self, RbValue tone)
    {
        self.GetRDataObject<PlaneData>().Tone = tone.GetRDataObject<ToneData>();
        return state.RbNil;
    }

    [RbInstanceMethod("color")]
    public static RbValue GetColor(RbState state, RbValue self)
    {
        var color = self.GetRDataObject<PlaneData>().Color;
        return Color.CreateColor(state,
            (color?.R ?? 0.0f) * 255.0f,
            (color?.G ?? 0.0f) * 255.0f,
            (color?.B ?? 0.0f) * 255.0f,
            (color?.A ?? 0.0f) * 255.0f);
    }

    [RbInstanceMethod("color=")]
    public static RbValue SetColor(RbState state, RbValue self, RbValue color)
    {
        self.GetRDataObject<PlaneData>().Color = color.GetRDataObject<ColorData>();
        return state.RbNil;
    }

    [RbInstanceMethod("visible")]
    public static RbValue GetVisible(RbState state, RbValue self)
        => self.GetRDataObject<PlaneData>().Visible.ToValue(state);

    [RbInstanceMethod("visible=")]
    public static RbValue SetVisible(RbState state, RbValue self, RbValue visible)
    {
        self.GetRDataObject<PlaneData>().Visible = visible.IsTrue;
        return state.RbNil;
    }

    [RbInstanceMethod("z")]
    public static RbValue GetZ(RbState state, RbValue self)
        => self.GetRDataObject<PlaneData>().Z.ToValue(state);

    [RbInstanceMethod("z=")]
    public static RbValue SetZ(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<PlaneData>().Z = (int)value.ToIntUnchecked();
        return state.RbNil;
    }

    [RbInstanceMethod("ox")]
    public static RbValue GetOx(RbState state, RbValue self)
        => self.GetRDataObject<PlaneData>().Ox.ToValue(state);

    [RbInstanceMethod("ox=")]
    public static RbValue SetOx(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<PlaneData>().Ox = (int)value.ToIntUnchecked();
        return state.RbNil;
    }

    [RbInstanceMethod("oy")]
    public static RbValue GetOy(RbState state, RbValue self)
        => self.GetRDataObject<PlaneData>().Oy.ToValue(state);

    [RbInstanceMethod("oy=")]
    public static RbValue SetOy(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<PlaneData>().Oy = (int)value.ToIntUnchecked();
        return state.RbNil;
    }

    [RbInstanceMethod("zoom_x")]
    public static RbValue GetZoomX(RbState state, RbValue self)
        => self.GetRDataObject<PlaneData>().ZoomX.ToValue(state);

    [RbInstanceMethod("zoom_x=")]
    public static RbValue SetZoomX(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<PlaneData>().ZoomX = ToFloat(value);
        return state.RbNil;
    }

    [RbInstanceMethod("zoom_y")]
    public static RbValue GetZoomY(RbState state, RbValue self)
        => self.GetRDataObject<PlaneData>().ZoomY.ToValue(state);

    [RbInstanceMethod("zoom_y=")]
    public static RbValue SetZoomY(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<PlaneData>().ZoomY = ToFloat(value);
        return state.RbNil;
    }

    [RbInstanceMethod("opacity")]
    public static RbValue GetOpacity(RbState state, RbValue self)
        => self.GetRDataObject<PlaneData>().Opacity.ToValue(state);

    [RbInstanceMethod("opacity=")]
    public static RbValue SetOpacity(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<PlaneData>().Opacity = Math.Clamp((int)value.ToIntUnchecked(), 0, 255);
        return state.RbNil;
    }

    [RbInstanceMethod("blend_type")]
    public static RbValue GetBlendType(RbState state, RbValue self)
        => self.GetRDataObject<PlaneData>().BlendType.ToValue(state);

    [RbInstanceMethod("blend_type=")]
    public static RbValue SetBlendType(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<PlaneData>().BlendType = Math.Clamp((int)value.ToIntUnchecked(), 0, 2);
        return state.RbNil;
    }

    private static float ToFloat(RbValue value)
        => value.IsFloat ? Convert.ToSingle(value.ToFloatUnchecked()) : Convert.ToSingle(value.ToIntUnchecked());
}
