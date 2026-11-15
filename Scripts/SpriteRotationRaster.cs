using System;
using Godot;
using RGSSUnity.RubyClasses;

namespace RGSSUnity;

// RGSS300 samples integer screen positions, incrementing double UVs per row.
internal sealed class SpriteRotationRaster : IDisposable
{
    private (BitmapData, long, int, int, int, int, float, float, float, bool, int, int, int, int)? key;
    private ImageTexture? texture;
    private Vector2 offset;
    private int padding;

    public void Apply(Sprite2D node, SpriteData data)
    {
        var bitmap = data.Bitmap!;
        var rect = data.SrcRect!;
        var padding = (int)Math.Ceiling(Math.Max(0, data.WaveAmp));
        var current = (bitmap, bitmap.TextureRevision, data.X, data.Y, data.Ox, data.Oy,
            data.ZoomX, data.ZoomY, data.Angle, data.Mirror, rect.X, rect.Y, rect.Width, rect.Height);
        if (this.key != current)
        {
            var angle = -data.Angle * 2.0 * Math.PI / 360.0;
            var cosine = Math.Cos(angle);
            var sine = Math.Sin(angle);
            var left = int.MaxValue;
            var top = int.MaxValue;
            var right = int.MinValue;
            var bottom = int.MinValue;
            foreach (var x in new[] { 0, rect.Width })
            foreach (var y in new[] { 0, rect.Height })
            {
                var worldX = data.X + (x - data.Ox) * data.ZoomX * cosine - (y - data.Oy) * data.ZoomY * sine;
                var worldY = data.Y + (x - data.Ox) * data.ZoomX * sine + (y - data.Oy) * data.ZoomY * cosine;
                var roundedX = (int)Math.Floor(worldX + 0.5);
                var roundedY = (int)Math.Floor(worldY + 0.5);
                left = Math.Min(left, roundedX);
                right = Math.Max(right, roundedX);
                top = Math.Min(top, roundedY);
                bottom = Math.Max(bottom, roundedY);
            }
            left -= padding;
            right += padding;
            var width = right - left;
            var height = bottom - top;
            this.texture?.Dispose();
            this.texture = null;
            this.offset = new Vector2(left - data.X, top - data.Y);
            if (width > 0 && height > 0)
            {
                var pixels = new byte[checked(width * height * 4)];
                var source = bitmap.Image.GetData();
                var horizontalStep = data.Angle == 0 ? Math.Floor(65536.0 / data.ZoomX) / 65536.0 : cosine / data.ZoomX;
                var verticalStep = Math.Floor(65536.0 / data.ZoomY) / 65536.0;
                for (var y = top; y < bottom; y++)
                {
                    var u = rect.X + data.Ox + ((left - data.X) * cosine + (y - data.Y) * sine) / data.ZoomX;
                    var v = rect.Y + data.Oy + (-(left - data.X) * sine + (y - data.Y) * cosine) / data.ZoomY;
                    if (data.Angle == 0)
                        v = rect.Y + data.Oy + (top - data.Y) / (double)data.ZoomY + (y - top) * verticalStep;
                    if (data.Mirror)
                        u = rect.X + rect.Width - 1 - (u - rect.X);
                    for (var x = 0; x < width; x++)
                    {
                        if (u >= rect.X && u < rect.X + rect.Width && v >= rect.Y && v < rect.Y + rect.Height
                            && u >= 0 && u < bitmap.Width && v >= 0 && v < bitmap.Height)
                        {
                            var input = ((int)v * bitmap.Width + (int)u) * 4;
                            var output = ((y - top) * width + x) * 4;
                            Array.Copy(source, input, pixels, output, 4);
                        }
                        u += data.Mirror ? -horizontalStep : horizontalStep;
                        v += -sine / data.ZoomY;
                    }
                }
                using var image = Image.CreateFromData(width, height, false, Image.Format.Rgba8, pixels);
                this.texture = ImageTexture.CreateFromImage(image);
            }
            this.key = current;
            this.padding = padding;
        }
        node.Texture = this.texture;
        node.Offset = this.offset;
        node.Scale = Vector2.One;
        node.Rotation = 0;
        node.FlipH = false;
        node.RegionEnabled = false;
        if (node is SpriteDataNode spriteNode)
            spriteNode.RotationPadding = this.padding;
    }

    public void Dispose()
    {
        this.texture?.Dispose();
        this.texture = null;
    }
}
