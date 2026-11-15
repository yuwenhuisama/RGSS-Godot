using System;
using System.IO;
using Godot;
using MRuby.Library.Language;
using MRuby.Library.Mapper;
using RGSSGodot;
using RGSSUnity;

namespace RGSSUnity.RubyClasses;

[RbClass("Bitmap", "Object", "Unity")]
public static class Bitmap
{
    [RbClassMethod("new_wh")]
    public static RbValue NewWithWidthAndHeight(RbState state, RbValue self, RbValue width, RbValue height)
    {
        var w = (int)width.ToIntUnchecked();
        var h = (int)height.ToIntUnchecked();
        if (w <= 0 || h <= 0)
        {
            state.RaiseRGSSError("failed to create bitmap");
            return state.RbNil;
        }
        var image = Image.Create(w, h, false, Image.Format.Rgba8);
        image.Fill(new Godot.Color(0, 0, 0, 0));
        return CreateBitmapObject(state, image);
    }

    [RbClassMethod("new_filename")]
    public static RbValue NewWithFileName(RbState state, RbValue self, RbValue filename)
    {
        var relativePath = filename.ToStringUnchecked()!;
        var path = ResolveImagePath(RMProjectPath.Resolve(relativePath));
        if (!File.Exists(path) && !Path.IsPathRooted(relativePath) && !string.IsNullOrEmpty(GlobalConfig.Instance.RtpPath))
        {
            path = ResolveImagePath(Path.Combine(GlobalConfig.Instance.RtpPath, relativePath));
        }

        if (!File.Exists(path))
        {
            state.RaiseRGSSError($"Failed to load image data, file not found: {relativePath}");
            return state.RbNil;
        }

        var image = Image.LoadFromFile(path);
        if (image is null || image.IsEmpty())
        {
            state.RaiseRGSSError($"Failed to load image data, invalid image data: {relativePath}");
            return state.RbNil;
        }

        if (image.GetFormat() != Image.Format.Rgba8)
            image.Convert(Image.Format.Rgba8);

        return CreateBitmapObject(state, image);
    }

    // Non-raising existence probe for the RTP-fallback path selection in Ruby
    // (Cache.load_bitmap). Uses the SAME RMProjectPath.Resolve as new_filename so
    // the check matches the loader path exactly. Raising RGSSError from a binding
    // cannot be caught by Ruby `rescue` across the mruby-dotnet callback boundary,
    // so the fallback decision must be made in Ruby BEFORE calling Bitmap.new.
    [RbClassMethod("file_exists?")]
    public static RbValue FileExists(RbState state, RbValue self, RbValue filename)
    {
        var relativePath = filename.ToStringUnchecked()!;
        var path = ResolveImagePath(RMProjectPath.Resolve(relativePath));
        return File.Exists(path).ToValue(state);
    }

    private static string ResolveImagePath(string path)
    {
        if (!Path.HasExtension(path)) path += ".png";
        if (File.Exists(path) || OperatingSystem.IsWindows()) return path;

        // RMVA projects use Windows filename matching, including stock Iconset
        // requests for the RTP's IconSet.png on case-sensitive filesystems.
        var current = Path.GetPathRoot(path)!;
        foreach (var part in path[current.Length..].Split(Path.DirectorySeparatorChar))
        {
            var exact = Path.Combine(current, part);
            if (File.Exists(exact) || Directory.Exists(exact))
            {
                current = exact;
                continue;
            }
            if (!Directory.Exists(current)) return path;
            string? match = null;
            foreach (var entry in Directory.EnumerateFileSystemEntries(current))
            {
                if (!string.Equals(Path.GetFileName(entry), part, StringComparison.OrdinalIgnoreCase)) continue;
                if (match == null || string.CompareOrdinal(entry, match) < 0) match = entry;
            }
            if (match == null) return path;
            current = match;
        }
        return current;
    }

    [RbInstanceMethod("dispose")]
    public static RbValue Dispose(RbState state, RbValue self)
    {
        // Idempotent, like native RGSS3: disposing an already-disposed bitmap is a
        // no-op rather than an error. Do NOT route through GetBitmapData (it throws
        // when Disposed). RMVA disposes bitmaps in many paths and is not always guarded
        // by `disposed?`, so a double dispose must not crash.
        var data = self.GetRDataObject<BitmapData>();
        if (!data.Disposed)
            data.ReleaseResources();
        return state.RbNil;
    }

    [RbInstanceMethod("disposed?")]
    public static RbValue Disposed(RbState state, RbValue self)
        // MUST be safe to call on an already-disposed bitmap (do NOT route through
        // GetBitmapData, which throws when Disposed). RMVA's Cache relies on this:
        // Window_Base#draw_face does `Cache.face(name)` then `bitmap.dispose`, leaving a
        // disposed Bitmap in the cache hash; the next Cache.face -> Cache.include? calls
        // `@cache[key].disposed?` and expects `true` so it can reload the bitmap. If this
        // raised, the second face draw (e.g. opening the Item sub-menu) would crash.
        => self.GetRDataObject<BitmapData>().Disposed.ToValue(state);

    [RbInstanceMethod("width")]
    public static RbValue Width(RbState state, RbValue self)
        => GetBitmapData(self).Width.ToValue(state);

    [RbInstanceMethod("height")]
    public static RbValue Height(RbState state, RbValue self)
        => GetBitmapData(self).Height.ToValue(state);

    [RbInstanceMethod("font")]
    public static RbValue Font(RbState state, RbValue self)
        => self["@font"];

    [RbInstanceMethod("font=")]
    public static RbValue SetFont(RbState state, RbValue self, RbValue font)
    {
        var data = GetBitmapData(self);
        data.FontData = font.GetRDataObject<FontData>();
        self["@font"] = font;
        return state.RbNil;
    }

    [RbInstanceMethod("rect")]
    public static RbValue GetRect(RbState state, RbValue self)
        => self["@rect"];

    [RbInstanceMethod("rect=")]
    public static RbValue SetRect(RbState state, RbValue self, RbValue rect)
    {
        self["@rect"] = rect;
        return state.RbNil;
    }

    [RbInstanceMethod("blt")]
    public static RbValue Blt(RbState state, RbValue self, RbValue x, RbValue y, RbValue srcBitmap, RbValue srcRect, RbValue opacity)
    {
        var destData = GetBitmapData(self);
        var srcData = GetBitmapData(srcBitmap);
        var rect = srcRect.GetRDataObject<RectData>();
        var destX = (int)x.ToIntUnchecked();
        var destY = (int)y.ToIntUnchecked();
        var opacityValue = Clamp01(opacity.ToIntUnchecked() / 255.0f);

        BlendImage(destData.Image, srcData.Image, rect.X, rect.Y, rect.Width, rect.Height, destX, destY, opacityValue);
        destData.MarkDirty();
        return state.RbNil;
    }

    [RbInstanceMethod("stretch_blt")]
    public static RbValue StretchBlt(RbState state, RbValue self, RbValue destRect, RbValue srcBitmap, RbValue srcRect, RbValue opacity)
    {
        var destData = GetBitmapData(self);
        var srcData = GetBitmapData(srcBitmap);
        var src = srcRect.GetRDataObject<RectData>();
        var dest = destRect.GetRDataObject<RectData>();
        var opacityValue = Clamp01(opacity.ToIntUnchecked() / 255.0f);

        StretchBlendImage(destData.Image, srcData.Image, src, dest, opacityValue);
        destData.MarkDirty();
        return state.RbNil;
    }

    [RbInstanceMethod("fill_rect")]
    public static RbValue FillRect(RbState state, RbValue self, RbValue x, RbValue y, RbValue w, RbValue h, RbValue color)
    {
        var data = GetBitmapData(self);
        var rect = ClampRect((int)x.ToIntUnchecked(), (int)y.ToIntUnchecked(), (int)w.ToIntUnchecked(), (int)h.ToIntUnchecked(), data.Width, data.Height);
        if (rect.Size.X > 0 && rect.Size.Y > 0)
        {
            data.Image.FillRect(rect, ToGodotColor(color.GetRDataObject<ColorData>()));
            data.MarkDirty();
        }

        return state.RbNil;
    }

    [RbInstanceMethod("clear_rect")]
    public static RbValue ClearRect(RbState state, RbValue self, RbValue x, RbValue y, RbValue w, RbValue h)
    {
        var data = GetBitmapData(self);
        var rect = ClampRect((int)x.ToIntUnchecked(), (int)y.ToIntUnchecked(), (int)w.ToIntUnchecked(), (int)h.ToIntUnchecked(), data.Width, data.Height);
        if (rect.Size.X > 0 && rect.Size.Y > 0)
        {
            data.Image.FillRect(rect, new Godot.Color(0, 0, 0, 0));
            data.MarkDirty();
        }

        return state.RbNil;
    }

    [RbInstanceMethod("clear")]
    public static RbValue Clear(RbState state, RbValue self)
    {
        var data = GetBitmapData(self);
        data.Image.Fill(new Godot.Color(0, 0, 0, 0));
        data.MarkDirty();
        return state.RbNil;
    }

    [RbInstanceMethod("get_pixel")]
    public static RbValue GetPixel(RbState state, RbValue self, RbValue x, RbValue y)
    {
        var data = GetBitmapData(self);
        var px = (int)x.ToIntUnchecked();
        var py = (int)y.ToIntUnchecked();

        if (px < 0 || py < 0 || px >= data.Width || py >= data.Height)
            return Color.CreateColor(state, 0, 0, 0, 0);

        var color = data.Image.GetPixel(px, py);
        return Color.CreateColor(state, ToRgssChannel(color.R), ToRgssChannel(color.G), ToRgssChannel(color.B), ToRgssChannel(color.A));
    }

    [RbInstanceMethod("set_pixel")]
    public static RbValue SetPixel(RbState state, RbValue self, RbValue x, RbValue y, RbValue color)
    {
        var data = GetBitmapData(self);
        var px = (int)x.ToIntUnchecked();
        var py = (int)y.ToIntUnchecked();

        if (px >= 0 && py >= 0 && px < data.Width && py < data.Height)
        {
            data.Image.SetPixel(px, py, ToGodotColor(color.GetRDataObject<ColorData>()));
            data.MarkDirty();
        }

        return state.RbNil;
    }

    [RbInstanceMethod("hue_change")]
    public static RbValue HueChange(RbState state, RbValue self, RbValue hue)
    {
        var data = GetBitmapData(self);
        var shift = (int)hue.ToIntUnchecked();
        if (shift == 0) return state.RbNil;

        for (var py = 0; py < data.Height; py++)
        {
            for (var px = 0; px < data.Width; px++)
            {
                var color = data.Image.GetPixel(px, py);
                var r = (int)MathF.Round(color.R * 255);
                var g = (int)MathF.Round(color.G * 255);
                var b = (int)MathF.Round(color.B * 255);
                var maximum = Math.Max(r, Math.Max(g, b));
                var minimum = Math.Min(r, Math.Min(g, b));
                var delta = maximum - minimum;
                var lightness = (maximum + minimum) / 2;
                var saturation = delta == 0 ? 0 : 255 * delta / (maximum + minimum <= 255
                    ? maximum + minimum : 510 - maximum - minimum);
                var baseHue = delta == 0 ? 0 : maximum == r ? 60.0 * (g - b) / delta
                    : maximum == g ? 120.0 + 60.0 * (b - r) / delta : 240.0 + 60.0 * (r - g) / delta;
                var nextHue = (((int)Math.Round(baseHue, MidpointRounding.AwayFromZero) + shift) % 360 + 360) % 360;
                var amplitude = (lightness <= 128 ? lightness : 255 - lightness) * saturation / 255;
                var low = lightness - amplitude;
                var high = lightness + amplitude;
                var ramp = 2.0 * amplitude * (nextHue % 60) / 60;
                var converted = (nextHue / 60) switch
                {
                    0 => new Godot.Color(high / 255f, (int)(low + ramp) / 255f, low / 255f, color.A),
                    1 => new Godot.Color((int)(high - ramp) / 255f, high / 255f, low / 255f, color.A),
                    2 => new Godot.Color(low / 255f, high / 255f, (int)(low + ramp) / 255f, color.A),
                    3 => new Godot.Color(low / 255f, (int)(high - ramp) / 255f, high / 255f, color.A),
                    4 => new Godot.Color((int)(low + ramp) / 255f, low / 255f, high / 255f, color.A),
                    _ => new Godot.Color(high / 255f, low / 255f, (int)(high - ramp) / 255f, color.A),
                };
                data.Image.SetPixel(px, py, converted);
            }
        }

        data.MarkDirty();
        return state.RbNil;
    }

    [RbInstanceMethod("blur")]
    public static RbValue Blur(RbState state, RbValue self)
    {
        var data = GetBitmapData(self);
        using var source = data.Image.GetRegion(new Rect2I(0, 0, data.Width, data.Height));

        for (var py = 0; py < data.Height; py++)
        {
            for (var px = 0; px < data.Width; px++)
            {
                var accR = 0.0f;
                var accG = 0.0f;
                var accB = 0.0f;
                var accA = 0.0f;

                for (var oy = -1; oy <= 1; oy++)
                {
                    for (var ox = -1; ox <= 1; ox++)
                    {
                        var sample = source.GetPixel(Math.Clamp(px + ox, 0, data.Width - 1), Math.Clamp(py + oy, 0, data.Height - 1));
                        accR += sample.R;
                        accG += sample.G;
                        accB += sample.B;
                        accA += sample.A;
                    }
                }

                data.Image.SetPixel(px, py, new Godot.Color(accR / 9.0f, accG / 9.0f, accB / 9.0f, accA / 9.0f));
            }
        }

        data.MarkDirty();
        return state.RbNil;
    }

    [RbInstanceMethod("radial_blur")]
    public static RbValue RadialBlur(RbState state, RbValue self, RbValue angle, RbValue division)
    {
        var data = GetBitmapData(self);
        var angleValue = Math.Clamp((float)angle.ToIntUnchecked(), 0, 359);
        var divisions = Math.Clamp((int)division.ToIntUnchecked(), 2, 100);
        using var source = data.Image.GetRegion(new Rect2I(0, 0, data.Width, data.Height));
        var centerX = data.Width / 2.0f;
        var centerY = data.Height / 2.0f;

        for (var py = 0; py < data.Height; py++)
        {
            for (var px = 0; px < data.Width; px++)
            {
                var accum = new Godot.Color(0, 0, 0, 0);
                for (var i = 0; i < divisions; i++)
                {
                    var radians = MathF.PI * 2.0f * (-angleValue / 2 + (angleValue / (divisions - 1)) * i) / 360.0f;
                    var dx = px - centerX;
                    var dy = py - centerY;
                    var sx = (int)MathF.Round(centerX + (dx * MathF.Cos(radians)) - (dy * MathF.Sin(radians)));
                    var sy = (int)MathF.Round(centerY + (dx * MathF.Sin(radians)) + (dy * MathF.Cos(radians)));
                    sx = (sx % (2 * data.Width) + 2 * data.Width) % (2 * data.Width);
                    sy = (sy % (2 * data.Height) + 2 * data.Height) % (2 * data.Height);
                    if (sx >= data.Width) sx = 2 * data.Width - sx - 1;
                    if (sy >= data.Height) sy = 2 * data.Height - sy - 1;
                    var sample = source.GetPixel(sx, sy);
                    accum.R += MathF.Round(sample.R * 255);
                    accum.G += MathF.Round(sample.G * 255);
                    accum.B += MathF.Round(sample.B * 255);
                    accum.A += MathF.Round(sample.A * 255);
                }

                data.Image.SetPixel(px, py, new Godot.Color(
                    MathF.Truncate(accum.R / divisions) / 255,
                    MathF.Truncate(accum.G / divisions) / 255,
                    MathF.Truncate(accum.B / divisions) / 255,
                    MathF.Truncate(accum.A / divisions) / 255));
            }
        }

        data.MarkDirty();
        return state.RbNil;
    }

    [RbInstanceMethod("draw_text")]
    public static RbValue DrawText(RbState state, RbValue self, RbValue x, RbValue y, RbValue w, RbValue h, RbValue text, RbValue align)
    {
        var data = GetBitmapData(self);
        var fontData = GetFontData(data);
        var str = Utf8String(text);
        if (str.Length == 0)
            return state.RbNil;

        if (OperatingSystem.IsWindows())
        {
            DrawNativeText(data.Image, fontData, str, new Rect2I((int)x.ToIntUnchecked(), (int)y.ToIntUnchecked(),
                Math.Max(0, (int)w.ToIntUnchecked()), Math.Max(0, (int)h.ToIntUnchecked())), (int)align.ToIntUnchecked());
            data.MarkDirty();
            return state.RbNil;
        }

        DrawTextToImage(
            data.Image,
            (int)x.ToIntUnchecked(), (int)y.ToIntUnchecked(),
            Math.Max(0, (int)w.ToIntUnchecked()), Math.Max(0, (int)h.ToIntUnchecked()),
            str,
            Math.Max(1, fontData.Size),
            ToGodotColor(fontData.Color),
            (int)align.ToIntUnchecked(),
            fontData.Outline,
            ToGodotColor(fontData.OutlineColor));

        data.MarkDirty();
        return state.RbNil;
    }

    private static void DrawNativeText(Image destination, FontData font, string text, Rect2I rect, int align)
    {
        if (rect.Size.X == 0 || rect.Size.Y == 0)
            return;
        using var raster = FontMetrics.Rasterize(font, text, rect.Size.X, out var measured, out var rawCoverage);
        using var coverageMap = rawCoverage;
        var width = measured.X + (font.Outline ? 2 : 0);
        var originX = rect.Position.X + Math.Max(0, align == 1 ? (rect.Size.X - width + (font.Outline ? 1 : 0)) / 2 : align == 2 ? rect.Size.X - width : 0);
        var originY = rect.Position.Y + Math.Max(0, (rect.Size.Y - measured.Y - (font.Outline ? 2 : 0)) / 2);
        var color = ToGodotColor(font.Color);
        var outlineColor = ToGodotColor(font.OutlineColor);
        outlineColor.A *= color.A;
        if (font.Shadow)
        for (var y = 0; y < Math.Min(raster.GetHeight(), rect.Size.Y - (font.Outline ? 1 : 0)); y++)
        for (var x = 0; x < raster.GetWidth(); x++)
        {
            var coverage = raster.GetPixel(x, y).A;
            BlendTextPixel(destination, originX + x + 1, originY + y + 1, rect, new Godot.Color(0, 0, 0, color.A * coverage));
        }
        if (font.Outline)
        for (var oy = -1; oy <= 1; oy += 2)
        for (var passX = 0; passX < 2; passX++)
        for (var y = 0; y < Math.Min(raster.GetHeight(), rect.Size.Y - 1); y++)
        for (var x = 0; x < raster.GetWidth(); x++)
        {
            var ox = oy < 0 ? passX * 2 - 1 : 1 - passX * 2;
            var coverage = raster.GetPixel(x, y).A;
            var edgeColor = outlineColor;
            var grayLevel = (int)Math.Round(coverageMap.GetPixel(x, y).R * 255.0f);
            edgeColor.A = (int)Math.Round(outlineColor.A * grayLevel / 64.0f * 255.0f) / 255.0f;
            BlendTextPixel(destination, originX + x + ox, originY + y + oy, rect, edgeColor);
        }
        for (var y = 0; y < Math.Min(raster.GetHeight(), rect.Size.Y - (font.Outline ? 1 : 0)); y++)
        for (var x = 0; x < raster.GetWidth(); x++)
        {
            var pixel = color;
            pixel.A *= raster.GetPixel(x, y).A;
            BlendTextPixel(destination, originX + x, originY + y, rect, pixel);
        }
    }

    private static void BlendTextPixel(Image destination, int x, int y, Rect2I clip, Godot.Color color)
    {
        if (color.A <= 0 || !clip.HasPoint(new Vector2I(x, y)) || x < 0 || y < 0 || x >= destination.GetWidth() || y >= destination.GetHeight())
            return;
        var original = destination.GetPixel(x, y);
        destination.SetPixel(x, y, AlphaOver(color, original));
    }

    // CPU text rasterization onto a Godot.Image via the TextServer FreeType glyph
    // cache. Unlike the previous SubViewport+GetImage approach this is fully
    // headless-safe: TextServer is independent of the (dummy) RenderingServer, so
    // FontRenderGlyph/FontGetTextureImage operate on real CPU Images even under
    // --headless. (Source-verified against godot 4.6 text_server_fb.cpp.)
    private static void DrawTextToImage(Image dest, int x, int y, int w, int h, string text, int fontSize, Godot.Color color, int align, bool outline, Godot.Color outlineColor)
    {
        var ts = TextServerManager.GetPrimaryInterface();
        var font = ThemeDB.Singleton.FallbackFont;
        if (ts is null || font is null)
            return;

        var fontRids = font.GetRids();
        if (fontRids.Count == 0)
            return;

        foreach (var fr in fontRids)
        {
            ts.FontSetMultichannelSignedDistanceField(fr, false);
            ts.FontSetSubpixelPositioning(fr, TextServer.SubpixelPositioning.Disabled);
        }

        var shaped = ts.CreateShapedText();
        try
        {
            ts.ShapedTextAddString(shaped, text, fontRids, fontSize);
            ts.ShapedTextShape(shaped);

            var textWidth = ts.ShapedTextGetWidth(shaped);
            var ascent = ts.ShapedTextGetAscent(shaped);
            var descent = ts.ShapedTextGetDescent(shaped);

            var penX = align switch
            {
                1 => x + (w - textWidth) * 0.5,   // center
                2 => x + w - textWidth,            // right
                _ => (double)x,                    // left
            };
            var baselineY = y + (h + ascent - descent) * 0.5;

            var clip = new Rect2I(x, y, w, h);
            var glyphs = ts.ShapedTextGetGlyphs(shaped);
            foreach (var glyph in glyphs)
            {
                var glyphFontRid = glyph["font_rid"].AsRid();
                var glyphFontSize = glyph["font_size"].AsInt32();
                var glyphIndex = glyph["index"].AsInt32();
                var offset = glyph["offset"].AsVector2();
                var advance = glyph["advance"].AsDouble();

                if (glyphFontRid.IsValid && glyphIndex != 0)
                {
                    if (outline)
                        BlitGlyph(dest, ts, glyphFontRid, glyphFontSize, glyphIndex, 1, penX + offset.X, baselineY + offset.Y, clip, outlineColor);

                    BlitGlyph(dest, ts, glyphFontRid, glyphFontSize, glyphIndex, 0, penX + offset.X, baselineY + offset.Y, clip, color);
                }

                penX += advance;
            }
        }
        finally
        {
            ts.FreeRid(shaped);
        }
    }

    private static void BlitGlyph(Image dest, TextServer ts, Rid fontRid, int fontSize, int glyphIndex, int outlineWidth, double penX, double penY, Rect2I clip, Godot.Color color)
    {
        var sizeVec = new Vector2I(fontSize, outlineWidth);
        ts.FontRenderGlyph(fontRid, sizeVec, glyphIndex);

        var texIdx = ts.FontGetGlyphTextureIdx(fontRid, sizeVec, glyphIndex);
        if (texIdx < 0)
            return;

        var atlas = ts.FontGetTextureImage(fontRid, sizeVec, (int)texIdx);
        if (atlas is null)
            return;

        var uvRect = ts.FontGetGlyphUVRect(fontRid, sizeVec, glyphIndex);
        if (uvRect.Size.X <= 0 || uvRect.Size.Y <= 0)
            return;

        var bearing = ts.FontGetGlyphOffset(fontRid, sizeVec, glyphIndex);
        var srcX = (int)uvRect.Position.X;
        var srcY = (int)uvRect.Position.Y;
        var gW = (int)uvRect.Size.X;
        var gH = (int)uvRect.Size.Y;
        var dstOriginX = (int)Math.Round(penX + bearing.X);
        var dstOriginY = (int)Math.Round(penY + bearing.Y);

        var atlasW = atlas.GetWidth();
        var atlasH = atlas.GetHeight();
        var destW = dest.GetWidth();
        var destH = dest.GetHeight();

        for (var gy = 0; gy < gH; gy++)
        {
            var sy = srcY + gy;
            var dy = dstOriginY + gy;
            if (sy < 0 || sy >= atlasH || dy < clip.Position.Y || dy >= clip.Position.Y + clip.Size.Y || dy < 0 || dy >= destH)
                continue;

            for (var gx = 0; gx < gW; gx++)
            {
                var sx = srcX + gx;
                var dx = dstOriginX + gx;
                if (sx < 0 || sx >= atlasW || dx < clip.Position.X || dx >= clip.Position.X + clip.Size.X || dx < 0 || dx >= destW)
                    continue;

                // TextServer glyph atlas is LA8: GetPixel returns (L,L,L,A) where A is coverage.
                var coverage = atlas.GetPixel(sx, sy).A;
                if (coverage <= 0.001f)
                    continue;

                var srcA = coverage * color.A;
                if (srcA <= 0.0f)
                    continue;

                var dpx = dest.GetPixel(dx, dy);
                var outA = srcA + dpx.A * (1.0f - srcA);
                var blended = outA > 0.0001f
                    ? new Godot.Color(
                        (color.R * srcA + dpx.R * dpx.A * (1.0f - srcA)) / outA,
                        (color.G * srcA + dpx.G * dpx.A * (1.0f - srcA)) / outA,
                        (color.B * srcA + dpx.B * dpx.A * (1.0f - srcA)) / outA,
                        outA)
                    : Colors.Transparent;
                dest.SetPixel(dx, dy, blended);
            }
        }
    }

    [RbInstanceMethod("gradient_fill_rect")]
    public static RbValue GradientFillRect(RbState state, RbValue self, RbValue x, RbValue y, RbValue w, RbValue h, RbValue color1, RbValue color2, RbValue vertical)
    {
        var data = GetBitmapData(self);
        var rect = ClampRect((int)x.ToIntUnchecked(), (int)y.ToIntUnchecked(), (int)w.ToIntUnchecked(), (int)h.ToIntUnchecked(), data.Width, data.Height);
        if (rect.Size.X <= 0 || rect.Size.Y <= 0)
            return state.RbNil;

        var start = ToGodotColor(color1.GetRDataObject<ColorData>());
        var end = ToGodotColor(color2.GetRDataObject<ColorData>());
        var isVertical = vertical.IsTrue;
        var denom = Math.Max(1, (int)(isVertical ? h.ToIntUnchecked() : w.ToIntUnchecked()) - 1);

        for (var oy = 0; oy < rect.Size.Y; oy++)
        {
            for (var ox = 0; ox < rect.Size.X; ox++)
            {
                var t = (float)(isVertical ? oy : ox) / denom;
                data.Image.SetPixel(rect.Position.X + ox, rect.Position.Y + oy, LerpColor(start, end, t));
            }
        }

        data.MarkDirty();
        return state.RbNil;
    }

    [RbInstanceMethod("text_size")]
    public static RbValue TextSize(RbState state, RbValue self, RbValue text)
    {
        var fontData = GetFontData(GetBitmapData(self));
        var textValue = Utf8String(text);
        var size = FontMetrics.Measure(fontData, textValue);
        return Rect.CreateRect(state, 0, 0, size.X, size.Y);
    }

    // mruby strings are UTF-8 byte buffers; RbValue.ToStringUnchecked decodes them
    // with the platform ANSI codepage, which corrupts multibyte (e.g. Chinese)
    // text into mojibake on a non-UTF-8 system locale. Decode the raw bytes as
    // UTF-8 explicitly so RGSS string literals render correctly.
    private static string Utf8String(RbValue value)
    {
        if (!value.IsString)
            return string.Empty;

        var bytes = RbHelper.GetRawBytesFromRbStringObject(value);
        return bytes.Length == 0 ? string.Empty : System.Text.Encoding.UTF8.GetString(bytes);
    }

    internal static RbValue CreateBitmapObject(RbState state, Image image)
    {
        if (image.GetFormat() != Image.Format.Rgba8)
            image.Convert(Image.Format.Rgba8);

        var texture = ImageTexture.CreateFromImage(image);
        var data = new BitmapData(state)
        {
            Image = image,
            Texture = texture,
            Width = image.GetWidth(),
            Height = image.GetHeight(),
        };

        var cls = RubyScriptManager.Instance.GetClassUnderUnityModule("Bitmap");
        var res = cls.NewObjectWithRData(data);
        res["@font"] = state.RbNil;
        res["@rect"] = Rect.CreateRect(state, 0, 0, data.Width, data.Height);
        return res;
    }

    private static BitmapData GetBitmapData(RbValue self)
    {
        var data = self.GetRDataObject<BitmapData>();
        if (data.Disposed)
            throw new ObjectDisposedException(nameof(BitmapData));

        return data;
    }

    private static FontData GetFontData(BitmapData data)
    {
        if (data.FontData is not null)
            return data.FontData;

        data.FontData = new FontData(RubyScriptManager.Instance.State)
        {
            Names = ["Arial"],
            Size = 24,
            Color = new ColorData(RubyScriptManager.Instance.State) { R = 1, G = 1, B = 1, A = 1 },
            OutlineColor = new ColorData(RubyScriptManager.Instance.State) { R = 0, G = 0, B = 0, A = 0.5f },
            Outline = true,
        };
        return data.FontData;
    }

    private static void BlendImage(Image dest, Image src, int srcX, int srcY, int width, int height, int destX, int destY, float opacity)
    {
        if (opacity <= 0.0f || width <= 0 || height <= 0)
            return;

        var srcWidth = src.GetWidth();
        var srcHeight = src.GetHeight();
        var destWidth = dest.GetWidth();
        var destHeight = dest.GetHeight();

        for (var oy = 0; oy < height; oy++)
        {
            var sy = srcY + oy;
            var dy = destY + oy;
            if (sy < 0 || sy >= srcHeight || dy < 0 || dy >= destHeight)
                continue;

            for (var ox = 0; ox < width; ox++)
            {
                var sx = srcX + ox;
                var dx = destX + ox;
                if (sx < 0 || sx >= srcWidth || dx < 0 || dx >= destWidth)
                    continue;

                var source = src.GetPixel(sx, sy);
                source.A = ((int)MathF.Round(source.A * 255) * (int)MathF.Round(opacity * 255) / 255) / 255.0f;

                dest.SetPixel(dx, dy, AlphaOver(source, dest.GetPixel(dx, dy)));
            }
        }
    }

    private static void StretchBlendImage(Image dest, Image src, RectData srcRect, RectData destRect, float opacity)
    {
        if (opacity <= 0.0f || srcRect.Width <= 0 || srcRect.Height <= 0 || destRect.Width <= 0 || destRect.Height <= 0)
            return;

        var regionRect = ClampRect(srcRect.X, srcRect.Y, srcRect.Width, srcRect.Height, src.GetWidth(), src.GetHeight());
        if (regionRect.Size.X <= 0 || regionRect.Size.Y <= 0)
            return;

        var stepX = ((long)regionRect.Size.X << 16) / destRect.Width;
        var stepY = ((long)regionRect.Size.Y << 16) / destRect.Height;
        for (var y = 0; y < destRect.Height; y++)
        {
            var dy = destRect.Y + y;
            if (dy < 0 || dy >= dest.GetHeight()) continue;
            var sy = regionRect.Position.Y + (int)((y * stepY) >> 16);
            for (var x = 0; x < destRect.Width; x++)
            {
                var dx = destRect.X + x;
                if (dx < 0 || dx >= dest.GetWidth()) continue;
                var sx = regionRect.Position.X + (int)((x * stepX) >> 16);
                var source = src.GetPixel(sx, sy);
                source.A = ((int)MathF.Round(source.A * 255) * (int)MathF.Round(opacity * 255) / 255) / 255.0f;
                dest.SetPixel(dx, dy, AlphaOver(source, dest.GetPixel(dx, dy)));
            }
        }
    }

    private static Godot.Color AlphaOver(Godot.Color source, Godot.Color dest)
    {
        var sourceAlpha = (int)MathF.Round(source.A * 255);
        var destinationAlpha = (int)MathF.Round(dest.A * 255);
        if (destinationAlpha == 0) return source;
        if (sourceAlpha == 0) return dest;
        var numerator = 255 * sourceAlpha + destinationAlpha * (255 - sourceAlpha);
        var weight = 65025 * sourceAlpha / numerator + 1;
        return new Godot.Color(
            (((int)MathF.Round(source.R * 255) * weight + (int)MathF.Round(dest.R * 255) * (256 - weight)) >> 8) / 255.0f,
            (((int)MathF.Round(source.G * 255) * weight + (int)MathF.Round(dest.G * 255) * (256 - weight)) >> 8) / 255.0f,
            (((int)MathF.Round(source.B * 255) * weight + (int)MathF.Round(dest.B * 255) * (256 - weight)) >> 8) / 255.0f,
            (numerator / 255) / 255.0f);
    }

    private static Rect2I ClampRect(int x, int y, int w, int h, int maxW, int maxH)
    {
        var x1 = Math.Clamp(x, 0, maxW);
        var y1 = Math.Clamp(y, 0, maxH);
        var x2 = Math.Clamp(x + w, 0, maxW);
        var y2 = Math.Clamp(y + h, 0, maxH);
        return new Rect2I(x1, y1, Math.Max(0, x2 - x1), Math.Max(0, y2 - y1));
    }

    private static Godot.Color ToGodotColor(ColorData color)
        => new(NormalizeChannel(color.R), NormalizeChannel(color.G), NormalizeChannel(color.B), NormalizeChannel(color.A));

    private static float NormalizeChannel(float value)
        => Clamp01(value > 1.0f ? value / 255.0f : value);

    private static int ToRgssChannel(float value)
        => Math.Clamp((int)(Clamp01(value) * 255.0f), 0, 255);

    private static float Clamp01(float value)
        => Math.Clamp(value, 0.0f, 1.0f);

    private static Godot.Color LerpColor(Godot.Color left, Godot.Color right, float t)
    {
        t = Clamp01(t);
        return new Godot.Color(
            (MathF.Round(left.R * 255) + MathF.Truncate((MathF.Round(right.R * 255) - MathF.Round(left.R * 255)) * t)) / 255,
            (MathF.Round(left.G * 255) + MathF.Truncate((MathF.Round(right.G * 255) - MathF.Round(left.G * 255)) * t)) / 255,
            (MathF.Round(left.B * 255) + MathF.Truncate((MathF.Round(right.B * 255) - MathF.Round(left.B * 255)) * t)) / 255,
            (MathF.Round(left.A * 255) + MathF.Truncate((MathF.Round(right.A * 255) - MathF.Round(left.A * 255)) * t)) / 255);
    }
}
