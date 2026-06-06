using Godot;
using MRuby.Library.Language;

namespace RGSSUnity.RubyClasses;

public class WindowData : RubyData
{
    public BitmapData? Contents;
    public BitmapData? Windowskin;
    public ViewportData? Viewport;
    public RectData? CursorRect;

    public int X;
    public int Y;
    public int Z = 100;
    public int Width;
    public int Height;
    public int Ox;
    public int Oy;

    public bool Visible = true;
    public bool Active = true;
    public bool Pause;
    public bool ArrowsVisible = true;

    public int Opacity = 255;
    public int BackOpacity = 192;
    public int ContentsOpacity = 255;
    public int Openness = 255;

    public int Padding;
    public int PaddingBottom;

    public ToneData? Tone;
    public bool Disposed;

    public Node2D? Node;

    public WindowData(RbState state) : base(state)
    {
    }
}
