using MRuby.Library.Language;
using Godot;

namespace RGSSUnity.RubyClasses;

public class SpriteData : RubyData
{
    public BitmapData? Bitmap;
    public ViewportData? Viewport;

    public int X;
    public int Y;
    public int Z = 1;
    public int Ox;
    public int Oy;

    public float ZoomX = 1.0f;
    public float ZoomY = 1.0f;
    public float Angle;
    public bool Mirror;
    public bool Visible = true;
    public int Opacity = 255;
    public int BlendType;

    public RectData? SrcRect;
    public ToneData? Tone;
    public ColorData? Color;

    public float BushDepth;
    public int BushOpacity = 255;
    public float WaveAmp;
    public float WaveLength = 24.0f;
    public float WaveSpeed = 360.0f;
    public float WavePhase;

    public ColorData? FlashColor;
    public int FlashDuration;
    public int FlashRemain;

    public bool Disposed;
    public Sprite2D? Node;

    public SpriteData(RbState state) : base(state)
    {
    }
}
