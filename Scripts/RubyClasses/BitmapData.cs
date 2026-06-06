using Godot;
using MRuby.Library.Language;
using RGSSUnity;

namespace RGSSUnity.RubyClasses;

public class BitmapData : RubyData
{
    public Image Image = null!;
    public ImageTexture Texture = null!;
    public int Width;
    public int Height;
    public bool Dirty;
    public FontData? FontData;
    public bool Disposed;

    public BitmapData(RbState state) : base(state)
    {
    }

    public void MarkDirty()
    {
        if (this.Disposed)
            return;

        this.Dirty = true;
        GameRenderManager.DirtyBitmapDataSet.Add(this);
    }

    public void UpdateTexture()
    {
        if (!this.Dirty || this.Disposed || this.Image is null || this.Texture is null)
            return;

        this.Texture.Update(this.Image);
        this.Dirty = false;
    }

    public void ReleaseResources()
    {
        this.Dirty = false;
        this.Disposed = true;
        GameRenderManager.DirtyBitmapDataSet.Remove(this);
        this.Image = null!;
        this.Texture = null!;
        this.FontData = null;
        this.Width = 0;
        this.Height = 0;
    }
}
