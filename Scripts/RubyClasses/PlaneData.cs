using MRuby.Library.Language;
using Godot;

namespace RGSSUnity.RubyClasses;

public class PlaneData : RubyData
{
    public BitmapData? Bitmap;
    public ViewportData? Viewport;

    public int Ox;
    public int Oy;
    public float ZoomX = 1.0f;
    public float ZoomY = 1.0f;
    public int Z = 100;

    public bool Visible = true;
    public int Opacity = 255;
    public int BlendType;

    public ToneData? Tone;
    public ColorData? Color;
    public bool Disposed;

    // Godot node reference
    public Node2D? Node;

    public PlaneData(RbState state) : base(state)
    {
    }
}
