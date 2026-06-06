using System;
using MRuby.Library.Language;
using MRuby.Library.Mapper;

namespace RGSSUnity.RubyClasses;

[RbClass("Window", "Object", "Unity")]
public static class Window
{
    [RbClassMethod("new_with_viewport")]
    public static RbValue NewWithViewport(RbState state, RbValue self, RbValue viewport)
    {
        var viewportData = viewport.GetRDataObject<ViewportData>();
        return CreateWindow(state, self, 0, 0, 0, 0, viewport, viewportData);
    }

    [RbClassMethod("new_xywh")]
    public static RbValue NewXywh(RbState state, RbValue self, RbValue x, RbValue y, RbValue width, RbValue height, RbValue viewport)
    {
        var viewportData = viewport.GetRDataObject<ViewportData>();
        return CreateWindow(state, self, ToInt(x), ToInt(y), ToInt(width), ToInt(height), viewport, viewportData);
    }

    [RbInstanceMethod("dispose")]
    public static RbValue Dispose(RbState state, RbValue self)
    {
        var data = self.GetRDataObject<WindowData>();
        if (data.Disposed)
            return state.RbNil;

        GameRenderManager.Instance.UnregisterWindow(data);
        data.Disposed = true;
        data.Contents = null;
        data.Windowskin = null;
        data.Viewport = null;
        data.CursorRect = null;
        data.Tone = null;
        data.Node = null;
        return state.RbNil;
    }

    [RbInstanceMethod("disposed?")]
    public static RbValue Disposed(RbState state, RbValue self)
        => self.GetRDataObject<WindowData>().Disposed.ToValue(state);

    [RbInstanceMethod("update")]
    public static RbValue Update(RbState state, RbValue self) => state.RbNil;

    [RbInstanceMethod("open?")]
    public static RbValue Open(RbState state, RbValue self)
        => (self.GetRDataObject<WindowData>().Openness == 255).ToValue(state);

    [RbInstanceMethod("close?")]
    public static RbValue Close(RbState state, RbValue self)
        => (self.GetRDataObject<WindowData>().Openness == 0).ToValue(state);

    [RbInstanceMethod("move")]
    public static RbValue Move(RbState state, RbValue self, RbValue x, RbValue y, RbValue width, RbValue height)
    {
        var data = self.GetRDataObject<WindowData>();
        data.X = ToInt(x);
        data.Y = ToInt(y);
        data.Width = ToInt(width);
        data.Height = ToInt(height);
        return state.RbNil;
    }

    [RbInstanceMethod("contents")]
    public static RbValue GetContents(RbState state, RbValue self) => self["@contents"];

    [RbInstanceMethod("contents=")]
    public static RbValue SetContents(RbState state, RbValue self, RbValue contents)
    {
        self.GetRDataObject<WindowData>().Contents = contents.IsNil ? null : contents.GetRDataObject<BitmapData>();
        self["@contents"] = contents;
        return state.RbNil;
    }

    [RbInstanceMethod("windowskin")]
    public static RbValue GetWindowskin(RbState state, RbValue self) => self["@windowskin"];

    [RbInstanceMethod("windowskin=")]
    public static RbValue SetWindowskin(RbState state, RbValue self, RbValue windowskin)
    {
        self.GetRDataObject<WindowData>().Windowskin = windowskin.IsNil ? null : windowskin.GetRDataObject<BitmapData>();
        self["@windowskin"] = windowskin;
        return state.RbNil;
    }

    [RbInstanceMethod("cursor_rect")]
    public static RbValue GetCursorRect(RbState state, RbValue self) => self["@cursor_rect"];

    [RbInstanceMethod("cursor_rect=")]
    public static RbValue SetCursorRect(RbState state, RbValue self, RbValue cursorRect)
    {
        self.GetRDataObject<WindowData>().CursorRect = cursorRect.IsNil ? null : cursorRect.GetRDataObject<RectData>();
        self["@cursor_rect"] = cursorRect;
        return state.RbNil;
    }

    [RbInstanceMethod("viewport")]
    public static RbValue GetViewport(RbState state, RbValue self) => self["@viewport"];

    [RbInstanceMethod("viewport=")]
    public static RbValue SetViewport(RbState state, RbValue self, RbValue viewport)
    {
        var data = self.GetRDataObject<WindowData>();
        var viewportData = viewport.GetRDataObject<ViewportData>();
        GameRenderManager.Instance.RegisterWindow(data, viewportData);
        self["@viewport"] = viewport;
        return state.RbNil;
    }

    [RbInstanceMethod("x")]
    public static RbValue GetX(RbState state, RbValue self) => self.GetRDataObject<WindowData>().X.ToValue(state);

    [RbInstanceMethod("x=")]
    public static RbValue SetX(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().X = ToInt(value);
        return state.RbNil;
    }

    [RbInstanceMethod("y")]
    public static RbValue GetY(RbState state, RbValue self) => self.GetRDataObject<WindowData>().Y.ToValue(state);

    [RbInstanceMethod("y=")]
    public static RbValue SetY(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().Y = ToInt(value);
        return state.RbNil;
    }

    [RbInstanceMethod("z")]
    public static RbValue GetZ(RbState state, RbValue self) => self.GetRDataObject<WindowData>().Z.ToValue(state);

    [RbInstanceMethod("z=")]
    public static RbValue SetZ(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().Z = ToInt(value);
        return state.RbNil;
    }

    [RbInstanceMethod("width")]
    public static RbValue GetWidth(RbState state, RbValue self) => self.GetRDataObject<WindowData>().Width.ToValue(state);

    [RbInstanceMethod("width=")]
    public static RbValue SetWidth(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().Width = ToInt(value);
        return state.RbNil;
    }

    [RbInstanceMethod("height")]
    public static RbValue GetHeight(RbState state, RbValue self) => self.GetRDataObject<WindowData>().Height.ToValue(state);

    [RbInstanceMethod("height=")]
    public static RbValue SetHeight(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().Height = ToInt(value);
        return state.RbNil;
    }

    [RbInstanceMethod("ox")]
    public static RbValue GetOx(RbState state, RbValue self) => self.GetRDataObject<WindowData>().Ox.ToValue(state);

    [RbInstanceMethod("ox=")]
    public static RbValue SetOx(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().Ox = ToInt(value);
        return state.RbNil;
    }

    [RbInstanceMethod("oy")]
    public static RbValue GetOy(RbState state, RbValue self) => self.GetRDataObject<WindowData>().Oy.ToValue(state);

    [RbInstanceMethod("oy=")]
    public static RbValue SetOy(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().Oy = ToInt(value);
        return state.RbNil;
    }

    [RbInstanceMethod("visible")]
    public static RbValue GetVisible(RbState state, RbValue self) => self.GetRDataObject<WindowData>().Visible.ToValue(state);

    [RbInstanceMethod("visible=")]
    public static RbValue SetVisible(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().Visible = value.IsTrue;
        return state.RbNil;
    }

    [RbInstanceMethod("active")]
    public static RbValue GetActive(RbState state, RbValue self) => self.GetRDataObject<WindowData>().Active.ToValue(state);

    [RbInstanceMethod("active=")]
    public static RbValue SetActive(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().Active = value.IsTrue;
        return state.RbNil;
    }

    [RbInstanceMethod("pause")]
    public static RbValue GetPause(RbState state, RbValue self) => self.GetRDataObject<WindowData>().Pause.ToValue(state);

    [RbInstanceMethod("pause=")]
    public static RbValue SetPause(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().Pause = value.IsTrue;
        return state.RbNil;
    }

    [RbInstanceMethod("arrows_visible")]
    public static RbValue GetArrowsVisible(RbState state, RbValue self) => self.GetRDataObject<WindowData>().ArrowsVisible.ToValue(state);

    [RbInstanceMethod("arrows_visible=")]
    public static RbValue SetArrowsVisible(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().ArrowsVisible = value.IsTrue;
        return state.RbNil;
    }

    [RbInstanceMethod("opacity")]
    public static RbValue GetOpacity(RbState state, RbValue self) => self.GetRDataObject<WindowData>().Opacity.ToValue(state);

    [RbInstanceMethod("opacity=")]
    public static RbValue SetOpacity(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().Opacity = ClampOpacity(value);
        return state.RbNil;
    }

    [RbInstanceMethod("back_opacity")]
    public static RbValue GetBackOpacity(RbState state, RbValue self) => self.GetRDataObject<WindowData>().BackOpacity.ToValue(state);

    [RbInstanceMethod("back_opacity=")]
    public static RbValue SetBackOpacity(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().BackOpacity = ClampOpacity(value);
        return state.RbNil;
    }

    [RbInstanceMethod("contents_opacity")]
    public static RbValue GetContentsOpacity(RbState state, RbValue self) => self.GetRDataObject<WindowData>().ContentsOpacity.ToValue(state);

    [RbInstanceMethod("contents_opacity=")]
    public static RbValue SetContentsOpacity(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().ContentsOpacity = ClampOpacity(value);
        return state.RbNil;
    }

    [RbInstanceMethod("openness")]
    public static RbValue GetOpenness(RbState state, RbValue self) => self.GetRDataObject<WindowData>().Openness.ToValue(state);

    [RbInstanceMethod("openness=")]
    public static RbValue SetOpenness(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().Openness = ClampOpacity(value);
        return state.RbNil;
    }

    [RbInstanceMethod("padding")]
    public static RbValue GetPadding(RbState state, RbValue self) => self.GetRDataObject<WindowData>().Padding.ToValue(state);

    [RbInstanceMethod("padding=")]
    public static RbValue SetPadding(RbState state, RbValue self, RbValue value)
    {
        var data = self.GetRDataObject<WindowData>();
        data.Padding = ToInt(value);
        data.PaddingBottom = data.Padding;
        return state.RbNil;
    }

    [RbInstanceMethod("padding_bottom")]
    public static RbValue GetPaddingBottom(RbState state, RbValue self) => self.GetRDataObject<WindowData>().PaddingBottom.ToValue(state);

    [RbInstanceMethod("padding_bottom=")]
    public static RbValue SetPaddingBottom(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<WindowData>().PaddingBottom = ToInt(value);
        return state.RbNil;
    }

    [RbInstanceMethod("tone")]
    public static RbValue GetTone(RbState state, RbValue self)
    {
        var tone = self.GetRDataObject<WindowData>().Tone;
        return Tone.CreateTone(state,
            (tone?.Red ?? 0.0f) * 255.0f,
            (tone?.Green ?? 0.0f) * 255.0f,
            (tone?.Blue ?? 0.0f) * 255.0f,
            (tone?.Gray ?? 0.0f) * 255.0f);
    }

    [RbInstanceMethod("tone=")]
    public static RbValue SetTone(RbState state, RbValue self, RbValue tone)
    {
        self.GetRDataObject<WindowData>().Tone = tone.IsNil ? null : tone.GetRDataObject<ToneData>();
        return state.RbNil;
    }

    private static RbValue CreateWindow(RbState state, RbValue self, int x, int y, int width, int height, RbValue viewport, ViewportData viewportData)
    {
        var cursorRect = Rect.CreateRect(state, 0, 0, 0, 0);
        var data = new WindowData(state)
        {
            X = x,
            Y = y,
            Width = width,
            Height = height,
            Viewport = viewportData,
            CursorRect = cursorRect.GetRDataObject<RectData>(),
            Tone = new ToneData(state),
        };

        GameRenderManager.Instance.RegisterWindow(data, viewportData);

        var obj = self.ToClass().NewObjectWithRData(data);
        obj["@viewport"] = viewport;
        obj["@contents"] = state.RbNil;
        obj["@windowskin"] = state.RbNil;
        obj["@cursor_rect"] = cursorRect;
        return obj;
    }

    private static int ToInt(RbValue value)
        => value.IsFloat ? (int)value.ToFloatUnchecked() : (int)value.ToIntUnchecked();

    private static int ClampOpacity(RbValue value)
        => Math.Clamp(ToInt(value), 0, 255);
}
