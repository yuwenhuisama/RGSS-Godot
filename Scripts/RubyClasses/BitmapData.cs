using Godot;
using MRuby.Library.Language;
using RGSSUnity;

namespace RGSSUnity.RubyClasses;

public class BitmapData : RubyData
{
    public static int LiveResourceCount { get; private set; }
    public Image Image = null!;
    public ImageTexture Texture = null!;
    public int Width;
    public int Height;
    public bool Dirty;
    public long TextureRevision;
    public FontData? FontData;
    public bool Disposed;

    public BitmapData(RbState state) : base(state)
    {
        LiveResourceCount++;
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
        this.TextureRevision++;
        this.Dirty = false;
    }

    public void ReleaseResources()
    {
        if (!this.Disposed)
            LiveResourceCount--;
        this.Dirty = false;
        this.Disposed = true;
        GameRenderManager.DirtyBitmapDataSet.Remove(this);
        this.Texture?.Dispose();
        this.Image?.Dispose();
        this.Image = null!;
        this.Texture = null!;
        this.FontData = null;
        this.Width = 0;
        this.Height = 0;
    }
}
