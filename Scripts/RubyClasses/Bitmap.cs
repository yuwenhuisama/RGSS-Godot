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
        var w = Math.Max(1, (int)width.ToIntUnchecked());
        var h = Math.Max(1, (int)height.ToIntUnchecked());
        var image = Image.Create(w, h, false, Image.Format.Rgba8);
        image.Fill(Colors.Transparent);
        return CreateBitmapObject(state, image);
    }

    [RbClassMethod("new_filename")]
    public static RbValue NewWithFileName(RbState state, RbValue self, RbValue filename)
    {
        var relativePath = filename.ToStringUnchecked()!;
        var path = RMProjectPath.Resolve(relativePath);

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

    [RbInstanceMethod("dispose")]
    public static RbValue Dispose(RbState state, RbValue self)
    {
        GetBitmapData(self).ReleaseResources();
        return state.RbNil;
    }

    [RbInstanceMethod("disposed?")]
    public static RbValue Disposed(RbState state, RbValue self)
        => GetBitmapData(self).Disposed.ToValue(state);

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
            data.Image.FillRect(rect, Colors.Transparent);
            data.MarkDirty();
        }

        return state.RbNil;
    }

    [RbInstanceMethod("clear")]
    public static RbValue Clear(RbState state, RbValue self)
    {
        var data = GetBitmapData(self);
        data.Image.Fill(Colors.Transparent);
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
        var shift = (float)(hue.ToIntUnchecked() % 360) / 360.0f;

        for (var py = 0; py < data.Height; py++)
        {
            for (var px = 0; px < data.Width; px++)
            {
                var color = data.Image.GetPixel(px, py);
                var nextHue = color.H + shift;
                nextHue -= MathF.Floor(nextHue);
                data.Image.SetPixel(px, py, Godot.Color.FromHsv(nextHue, color.S, color.V, color.A));
            }
        }

        data.MarkDirty();
        return state.RbNil;
    }

    [RbInstanceMethod("blur")]
    public static RbValue Blur(RbState state, RbValue self)
    {
        var data = GetBitmapData(self);
        var source = data.Image.GetRegion(new Rect2I(0, 0, data.Width, data.Height));

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
        var angleValue = (float)angle.ToIntUnchecked();
        var divisions = Math.Max(1, (int)division.ToIntUnchecked());
        var source = data.Image.GetRegion(new Rect2I(0, 0, data.Width, data.Height));
        var centerX = (data.Width - 1) / 2.0f;
        var centerY = (data.Height - 1) / 2.0f;

        for (var py = 0; py < data.Height; py++)
        {
            for (var px = 0; px < data.Width; px++)
            {
                var accum = new Godot.Color(0, 0, 0, 0);
                for (var i = 0; i < divisions; i++)
                {
                    var radians = MathF.PI * 2.0f * ((angleValue / divisions) * i) / 360.0f;
                    var dx = px - centerX;
                    var dy = py - centerY;
                    var sx = Math.Clamp((int)MathF.Round(centerX + (dx * MathF.Cos(radians)) - (dy * MathF.Sin(radians))), 0, data.Width - 1);
                    var sy = Math.Clamp((int)MathF.Round(centerY + (dx * MathF.Sin(radians)) + (dy * MathF.Cos(radians))), 0, data.Height - 1);
                    var sample = source.GetPixel(sx, sy);
                    accum.R += sample.R;
                    accum.G += sample.G;
                    accum.B += sample.B;
                    accum.A += sample.A;
                }

                data.Image.SetPixel(px, py, new Godot.Color(accum.R / divisions, accum.G / divisions, accum.B / divisions, accum.A / divisions));
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
        var label = new Label
        {
            Text = text.ToStringUnchecked() ?? string.Empty,
            Position = new Vector2((int)x.ToIntUnchecked(), (int)y.ToIntUnchecked()),
            Size = new Vector2(Math.Max(0, (int)w.ToIntUnchecked()), Math.Max(0, (int)h.ToIntUnchecked())),
            ClipText = true,
            HorizontalAlignment = ToHorizontalAlignment((int)align.ToIntUnchecked()),
            VerticalAlignment = VerticalAlignment.Top,
            AutowrapMode = TextServer.AutowrapMode.Off,
            LabelSettings = new LabelSettings
            {
                FontSize = Math.Max(1, fontData.Size),
                FontColor = ToGodotColor(fontData.Color),
                OutlineSize = fontData.Outline ? 1 : 0,
                OutlineColor = ToGodotColor(fontData.OutlineColor),
                ShadowSize = fontData.Shadow ? 1 : 0,
                ShadowColor = new Godot.Color(0, 0, 0, 0.5f),
            },
        };

        var viewport = new SubViewport
        {
            Size = new Vector2I(data.Width, data.Height),
            TransparentBg = true,
            Disable3D = true,
            RenderTargetClearMode = SubViewport.ClearMode.Always,
            RenderTargetUpdateMode = SubViewport.UpdateMode.Once,
        };

        viewport.AddChild(label);

        var root = (Engine.GetMainLoop() as SceneTree)?.Root;
        if (root is not null)
        {
            root.AddChild(viewport);
            RenderingServer.ForceDraw(true, 0.0);
            var textImage = viewport.GetTexture().GetImage();
            if (textImage is not null && !textImage.IsEmpty())
            {
                if (textImage.GetFormat() != Image.Format.Rgba8)
                    textImage.Convert(Image.Format.Rgba8);

                BlendImage(data.Image, textImage, 0, 0, data.Width, data.Height, 0, 0, 1.0f);
                data.MarkDirty();
            }
        }

        viewport.QueueFree();
        return state.RbNil;
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
        var denom = Math.Max(1, (isVertical ? rect.Size.Y : rect.Size.X) - 1);

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
        var textValue = text.ToStringUnchecked() ?? string.Empty;
        var width = textValue.Length * Math.Max(1, fontData.Size);
        var height = Math.Max(1, fontData.Size);
        return Rect.CreateRect(state, 0, 0, width, height);
    }

    private static RbValue CreateBitmapObject(RbState state, Image image)
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
                source.A *= opacity;
                if (source.A <= 0.0f)
                    continue;

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

        var region = src.GetRegion(regionRect);
        region.Resize(Math.Max(1, destRect.Width), Math.Max(1, destRect.Height), Image.Interpolation.Bilinear);
        BlendImage(dest, region, 0, 0, region.GetWidth(), region.GetHeight(), destRect.X, destRect.Y, opacity);
    }

    private static Godot.Color AlphaOver(Godot.Color source, Godot.Color dest)
    {
        var invA = 1.0f - source.A;
        return new Godot.Color(
            Clamp01((source.R * source.A) + (dest.R * invA)),
            Clamp01((source.G * source.A) + (dest.G * invA)),
            Clamp01((source.B * source.A) + (dest.B * invA)),
            Clamp01(source.A + (dest.A * invA)));
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
            left.R + ((right.R - left.R) * t),
            left.G + ((right.G - left.G) * t),
            left.B + ((right.B - left.B) * t),
            left.A + ((right.A - left.A) * t));
    }

    private static HorizontalAlignment ToHorizontalAlignment(int align)
        => align switch
        {
            1 => HorizontalAlignment.Center,
            2 => HorizontalAlignment.Right,
            _ => HorizontalAlignment.Left,
        };
}
