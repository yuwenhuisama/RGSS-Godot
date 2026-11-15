using System;
using Godot;
using RGSSUnity.RubyClasses;

namespace RGSSUnity;

internal sealed class SpriteWaveRaster : IDisposable
{
    private (Texture2D, long, int, int, int, int, float, float, float, bool, float, float, int)? key;
    private ImageTexture? texture;
    private int padding;

    public void Apply(Sprite2D node, SpriteData data)
    {
        var bitmap = data.Bitmap!;
        var rect = data.SrcRect!;
        var rotated = data.Angle != 0;
        var inputTexture = rotated ? node.Texture : bitmap.Texture;
        var sourceWidth = rotated ? inputTexture.GetWidth() : bitmap.Width;
        var sourceHeight = rotated ? inputTexture.GetHeight() : bitmap.Height;
        var sourceXOrigin = rotated ? 0 : rect.X;
        var sourceYOrigin = rotated ? 0 : rect.Y;
        var regionWidth = rotated ? sourceWidth : rect.Width;
        var regionHeight = rotated ? sourceHeight : rect.Height;
        var inputOffset = node.Offset;
        var scale = node.Scale;
        var rotationPadding = rotated && node is SpriteDataNode spriteNode ? spriteNode.RotationPadding : 0;
        var outputWidth = (int)(regionWidth * scale.X) - rotationPadding * 2;
        var outputHeight = (int)(regionHeight * scale.Y);
        var worldTop = data.Y + (int)(inputOffset.Y * scale.Y);
        var current = (inputTexture, bitmap.TextureRevision, sourceXOrigin, sourceYOrigin, regionWidth, regionHeight,
            data.WaveAmp, data.WaveLength, data.WavePhase, data.Mirror, scale.X, scale.Y, worldTop);
        if (this.key != current)
        {
            this.padding = (int)Math.Ceiling(Math.Abs(data.WaveAmp));
            var width = checked(outputWidth + this.padding * 2);
            var pixels = new byte[checked(width * outputHeight * 4)];
            using var rotatedImage = rotated ? inputTexture.GetImage() : null;
            var source = rotated ? rotatedImage!.GetData() : bitmap.Image.GetData();
            for (var y = 0; y < outputHeight; y++)
            {
                var bandStart = Math.Max(0, (int)Math.Floor((worldTop + y) / 8.0) * 8 - worldTop);
                var degrees = data.WaveLength == 0 ? data.WavePhase : bandStart * 360.0 / data.WaveLength + data.WavePhase;
                var phase = (int)degrees * Math.PI / 180.0;
                var wave = data.WaveLength == 0 ? 0 : Math.Sin(phase);
                var shift = (int)Math.Floor(data.WaveAmp * wave + 0.5);
                for (var x = 0; x < outputWidth; x++)
                {
                    var sampledX = rotated
                        ? (int)((long)x * (((long)(outputWidth + this.padding * 2) << 16) / outputWidth) >> 16)
                        : (int)(x / scale.X);
                    var sourceX = sourceXOrigin + (!rotated && data.Mirror ? regionWidth - 1 - sampledX : sampledX);
                    var sourceY = sourceYOrigin + (int)(y / scale.Y);
                    if (sourceX < 0 || sourceX >= sourceWidth || sourceY < 0 || sourceY >= sourceHeight)
                        continue;
                    Array.Copy(source, (sourceY * sourceWidth + sourceX) * 4, pixels,
                        (y * width + x + this.padding + shift) * 4, 4);
                }
            }
            using var image = Image.CreateFromData(width, outputHeight, false, Image.Format.Rgba8, pixels);
            this.texture?.Dispose();
            this.texture = ImageTexture.CreateFromImage(image);
            this.key = current;
        }
        node.Texture = this.texture;
        node.Offset = inputOffset * scale + new Vector2(rotationPadding - this.padding, 0);
        node.Scale = Vector2.One;
        node.FlipH = false;
        node.RegionEnabled = false;
    }

    public void Dispose()
    {
        this.texture?.Dispose();
        this.texture = null;
    }
}
