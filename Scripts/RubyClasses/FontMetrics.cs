using System;
using System.Runtime.InteropServices;
using Godot;

namespace RGSSUnity.RubyClasses;

internal static class FontMetrics
{
    [StructLayout(LayoutKind.Sequential)]
    private struct Size
    {
        public int Width;
        public int Height;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct Fixed
    {
        public ushort Fraction;
        public short Value;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct Matrix
    {
        public Fixed M11;
        public Fixed M12;
        public Fixed M21;
        public Fixed M22;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct GlyphMetrics
    {
        public uint Width;
        public uint Height;
        public int OriginX;
        public int OriginY;
        public short AdvanceX;
        public short AdvanceY;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct TextMetrics
    {
        public int Height, Ascent, Descent, InternalLeading, ExternalLeading;
        public int AverageWidth, MaximumWidth, Weight, Overhang, AspectX, AspectY;
        public char First, Last, Default, Break;
        public byte Italic, Underlined, StruckOut, PitchAndFamily, Charset;
    }

    [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetTextMetricsW(IntPtr dc, out TextMetrics metrics);

    [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
    private static extern uint GetGlyphOutlineW(IntPtr dc, uint character, uint format,
        out GlyphMetrics metrics, uint bufferSize, IntPtr buffer, ref Matrix matrix);

    [DllImport("gdi32.dll")]
    private static extern IntPtr CreateCompatibleDC(IntPtr dc);

    [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
    private static extern IntPtr CreateFontW(int height, int width, int escapement, int orientation, int weight,
        uint italic, uint underline, uint strikeout, uint charset, uint outputPrecision,
        uint clipPrecision, uint quality, uint pitchAndFamily, string name);

    [DllImport("gdi32.dll")]
    private static extern IntPtr SelectObject(IntPtr dc, IntPtr value);

    [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetTextExtentPoint32W(IntPtr dc, string text, int length, out Size size);

    [DllImport("gdi32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DeleteObject(IntPtr value);

    [DllImport("gdi32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DeleteDC(IntPtr dc);

    internal static Vector2I Measure(FontData data, string text)
    {
        if (text.Length == 0)
            return Vector2I.Zero;

        if (!OperatingSystem.IsWindows())
        {
            using var font = new SystemFont
            {
                FontNames = data.Names,
                FontWeight = data.Bold ? 700 : 400,
                FontItalic = false,
                SubpixelPositioning = TextServer.SubpixelPositioning.Disabled,
            };
            var emSize = Math.Max(1, (int)Math.Round(data.Size * data.Size / font.GetHeight(data.Size)));
            var size = font.GetStringSize(text, HorizontalAlignment.Left, -1, emSize);
            return new Vector2I((int)Math.Round(size.X), data.Size);
        }

        using var fontContext = new NativeFont(data, false);
        return MeasureNative(fontContext.Dc, text);
    }

    private sealed class NativeFont : IDisposable
    {
        internal readonly IntPtr Dc;
        private readonly IntPtr handle;
        private readonly IntPtr previous;

        internal NativeFont(FontData data, bool italic, int width = 0)
        {
        var name = data.Names.Length > 0 ? data.Names[0] : "VL Gothic";
        foreach (var candidate in data.Names)
        {
            if (OS.GetSystemFontPath(candidate).Length == 0)
                continue;
            name = candidate;
            break;
        }
        var dc = CreateCompatibleDC(IntPtr.Zero);
        if (dc == IntPtr.Zero)
            throw new InvalidOperationException("Cannot create RGSS font measurement context.");
        this.handle = CreateFontW(data.Size, width, 0, 0, data.Bold ? 700 : 400, italic ? 1u : 0u, 0, 0, 1, 0, 0, 4, 0, name);
        if (handle == IntPtr.Zero)
        {
            DeleteDC(dc);
            throw new InvalidOperationException("Cannot create RGSS font for measurement.");
        }
        this.Dc = dc;
        this.previous = SelectObject(dc, this.handle);
        }

        public void Dispose()
        {
            SelectObject(this.Dc, this.previous);
            DeleteObject(this.handle);
            DeleteDC(this.Dc);
        }
    }

    private static Vector2I MeasureNative(IntPtr dc, string text, bool glyphAdvances = false)
    {
            // RGSS measures advances independently (no pair kerning), excluding
            // outline and italic overhang. Positive GDI height is the cell height.
            var width = 0;
            var height = 0;
            var left = 0;
            var matrix = new Matrix { M11 = new Fixed { Value = 1 }, M22 = new Fixed { Value = 1 } };
            foreach (var rune in text.EnumerateRunes())
            {
                var glyph = rune.ToString();
                if (!GetTextExtentPoint32W(dc, glyph, glyph.Length, out var size))
                    throw new InvalidOperationException("Cannot measure RGSS font glyph.");
                if (GetGlyphOutlineW(dc, (uint)rune.Value, 6, out var metrics, 0, IntPtr.Zero, ref matrix) != uint.MaxValue)
                {
                    left = Math.Min(left, width + metrics.OriginX);
                    if (glyphAdvances) size.Width = metrics.AdvanceX;
                }
                width += size.Width;
                height = Math.Max(height, size.Height);
            }
            return new Vector2I(width - left, height);
    }

    internal static Image Rasterize(FontData data, string text, int availableWidth, out Vector2I size, out Image coverage)
    {
        using var normal = new NativeFont(data, false);
        size = MeasureNative(normal.Dc, text);
        if (!GetTextMetricsW(normal.Dc, out var metrics))
            throw new InvalidOperationException("Cannot read RGSS font baseline.");
        var averageWidth = 0;
        if (availableWidth < size.X)
        {
            var scale = Math.Max(0.6, availableWidth / (double)size.X - 0.15);
            var referenceDc = CreateCompatibleDC(IntPtr.Zero);
            if (referenceDc == IntPtr.Zero)
                throw new InvalidOperationException("Cannot create RGSS font compression context.");
            try
            {
                if (!GetTextMetricsW(referenceDc, out var reference))
                    throw new InvalidOperationException("Cannot read RGSS font compression metrics.");
                averageWidth = (int)(data.Size * scale * reference.AverageWidth / reference.Height);
            }
            finally { DeleteDC(referenceDc); }
        }
        using var font = new NativeFont(data, data.Italic, averageWidth);
        using var advances = new NativeFont(data, false, averageWidth);
        size = MeasureNative(advances.Dc, text, true);
        if (!GetTextMetricsW(font.Dc, out metrics))
            throw new InvalidOperationException("Cannot read RGSS font baseline.");
        var image = Image.CreateEmpty(Math.Max(1, size.X + data.Size), Math.Max(1, size.Y), false, Image.Format.Rgba8);
        image.Fill(Colors.Transparent);
        coverage = Image.CreateEmpty(image.GetWidth(), image.GetHeight(), false, Image.Format.Rgba8);
        coverage.Fill(new Godot.Color(0, 0, 0, 0));
        var matrix = new Matrix { M11 = new Fixed { Value = 1 }, M22 = new Fixed { Value = 1 } };
        var penX = 0;
        var inkRight = 0;
        var firstGlyph = true;
        foreach (var rune in text.EnumerateRunes())
        {
            var count = GetGlyphOutlineW(font.Dc, (uint)rune.Value, 6, out var glyph, 0, IntPtr.Zero, ref matrix);
            if (count == uint.MaxValue)
                throw new InvalidOperationException($"Cannot rasterize RGSS glyph U+{rune.Value:X}.");
            if (firstGlyph)
            {
                penX = Math.Max(0, -glyph.OriginX);
                firstGlyph = false;
            }
            if (count > 0)
            {
                inkRight = Math.Max(inkRight, penX + glyph.OriginX + (int)glyph.Width);
                var buffer = Marshal.AllocHGlobal((int)count);
                try
                {
                    if (GetGlyphOutlineW(font.Dc, (uint)rune.Value, 6, out glyph, count, buffer, ref matrix) == uint.MaxValue)
                        throw new InvalidOperationException("Cannot read RGSS glyph raster.");
                    var bytes = new byte[count];
                    Marshal.Copy(buffer, bytes, 0, bytes.Length);
                    var stride = ((int)glyph.Width + 3) & ~3;
                    for (var y = 0; y < glyph.Height; y++)
                    for (var x = 0; x < glyph.Width; x++)
                    {
                        var dx = penX + glyph.OriginX + x;
                        var dy = metrics.Ascent - glyph.OriginY + y;
                        if (data.Outline && dx == 0)
                            continue;
                        if (dx < 0 || dx >= image.GetWidth() || dy < 0 || dy >= image.GetHeight())
                            continue;
                        var alpha = bytes[y * stride + x] / 64.0f;
                        image.SetPixel(dx, dy, new Godot.Color(1, 1, 1, alpha));
                        coverage.SetPixel(dx, dy, new Godot.Color(bytes[y * stride + x] / 255.0f, 0, 0, 1));
                    }
                }
                finally { Marshal.FreeHGlobal(buffer); }
            }
            penX += glyph.AdvanceX;
        }
        size = new Vector2I(Math.Max(size.X, inkRight), size.Y);
        return image;
    }
}
