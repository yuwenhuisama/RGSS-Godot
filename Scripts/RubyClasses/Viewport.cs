using System.Collections.Generic;
using Godot;
using MRuby.Library.Language;
using MRuby.Library.Mapper;
using RGSSGodot;

namespace RGSSUnity.RubyClasses
{
    [RbClass("Viewport", "Object", "Unity")]
    public static class Viewport
    {
        [RbClassMethod("new_without_rect")]
        public static RbValue NewWithoutRect(RbState state, RbValue self)
        {
            int vw = GlobalConfig.Instance.LegacyMode ? GlobalConfig.Instance.LegacyModeWidth : 544;
            int vh = GlobalConfig.Instance.LegacyMode ? GlobalConfig.Instance.LegacyModeHeight : 416;
            return CreateViewport(state, 0, 0, vw, vh);
        }

        [RbClassMethod("new_xyrw")]
        public static RbValue NewXyrw(RbState state, RbValue self,
            RbValue x, RbValue y, RbValue width, RbValue height)
        {
            return CreateViewport(state,
                (int)x.ToIntUnchecked(),
                (int)y.ToIntUnchecked(),
                (int)width.ToIntUnchecked(),
                (int)height.ToIntUnchecked());
        }

        [RbInstanceMethod("dispose")]
        public static RbValue Dispose(RbState state, RbValue self)
        {
            var data = self.GetRDataObject<ViewportData>();
            if (data.Disposed) return state.RbNil;
            GameRenderManager.Instance.UnregisterViewport(data);
            data.Disposed = true;
            return state.RbNil;
        }

        [RbInstanceMethod("disposed?")]
        public static RbValue Disposed(RbState state, RbValue self)
            => self.GetRDataObject<ViewportData>().Disposed ? state.RbTrue : state.RbFalse;

        [RbInstanceMethod("rect")]
        public static RbValue GetRect(RbState state, RbValue self)
        {
            var d = self.GetRDataObject<ViewportData>();
            return Rect.CreateRect(state, d.X, d.Y, d.Width, d.Height);
        }

        [RbInstanceMethod("rect=")]
        public static RbValue SetRect(RbState state, RbValue self, RbValue rect)
        {
            var d = self.GetRDataObject<ViewportData>();
            var rd = rect.GetRDataObject<RectData>();
            d.X = rd.X; d.Y = rd.Y; d.Width = rd.Width; d.Height = rd.Height;
            return rect;
        }

        [RbInstanceMethod("visible")]
        public static RbValue GetVisible(RbState state, RbValue self)
            => self.GetRDataObject<ViewportData>().Visible.ToValue(state);

        [RbInstanceMethod("visible=")]
        public static RbValue SetVisible(RbState state, RbValue self, RbValue visible)
        {
            self.GetRDataObject<ViewportData>().Visible = visible.IsTrue;
            return state.RbNil;
        }

        [RbInstanceMethod("ox")]
        public static RbValue GetOx(RbState state, RbValue self)
            => ((long)self.GetRDataObject<ViewportData>().Ox).ToValue(state);

        [RbInstanceMethod("ox=")]
        public static RbValue SetOx(RbState state, RbValue self, RbValue ox)
        {
            self.GetRDataObject<ViewportData>().Ox = (int)ox.ToIntUnchecked();
            return state.RbNil;
        }

        [RbInstanceMethod("oy")]
        public static RbValue GetOy(RbState state, RbValue self)
            => ((long)self.GetRDataObject<ViewportData>().Oy).ToValue(state);

        [RbInstanceMethod("oy=")]
        public static RbValue SetOy(RbState state, RbValue self, RbValue oy)
        {
            self.GetRDataObject<ViewportData>().Oy = (int)oy.ToIntUnchecked();
            return state.RbNil;
        }

        [RbInstanceMethod("z")]
        public static RbValue GetZ(RbState state, RbValue self)
            => ((long)self.GetRDataObject<ViewportData>().Z).ToValue(state);

        [RbInstanceMethod("z=")]
        public static RbValue SetZ(RbState state, RbValue self, RbValue z)
        {
            self.GetRDataObject<ViewportData>().Z = (int)z.ToIntUnchecked();
            return state.RbNil;
        }

        [RbInstanceMethod("tone")]
        public static RbValue GetTone(RbState state, RbValue self)
        {
            // Return the stored Tone wrapper so RGSS3 `viewport.tone.set(...)` (used by
            // Spriteset map/battle screen tinting) mutates the live ViewportData.Tone.
            var stored = self["@tone"];
            if (!stored.IsNil)
                return stored;

            var d = self.GetRDataObject<ViewportData>();
            var toneObj = Tone.CreateTone(state,
                (d.Tone?.Red ?? 0.0f) * 255.0f, (d.Tone?.Green ?? 0.0f) * 255.0f,
                (d.Tone?.Blue ?? 0.0f) * 255.0f, (d.Tone?.Gray ?? 0.0f) * 255.0f);
            d.Tone = toneObj.GetRDataObject<ToneData>();
            self["@tone"] = toneObj;
            return toneObj;
        }

        [RbInstanceMethod("tone=")]
        public static RbValue SetTone(RbState state, RbValue self, RbValue tone)
        {
            var d = self.GetRDataObject<ViewportData>();
            d.Tone = tone.IsNil ? null : tone.GetRDataObject<ToneData>();
            self["@tone"] = tone;
            return state.RbNil;
        }

        [RbInstanceMethod("color")]
        public static RbValue GetColor(RbState state, RbValue self)
        {
            // Return the stored Color wrapper so RGSS3 `viewport.color.set(...)`
            // (screen flash) mutates the live ViewportData.FlashColor.
            var stored = self["@color"];
            if (!stored.IsNil)
                return stored;

            var d = self.GetRDataObject<ViewportData>();
            var colorObj = Color.CreateColor(state,
                (d.FlashColor?.R ?? 0.0f) * 255.0f, (d.FlashColor?.G ?? 0.0f) * 255.0f,
                (d.FlashColor?.B ?? 0.0f) * 255.0f, (d.FlashColor?.A ?? 0.0f) * 255.0f);
            d.FlashColor = colorObj.GetRDataObject<ColorData>();
            self["@color"] = colorObj;
            return colorObj;
        }

        [RbInstanceMethod("color=")]
        public static RbValue SetColor(RbState state, RbValue self, RbValue color)
        {
            var d = self.GetRDataObject<ViewportData>();
            d.FlashColor = color.IsNil ? null : color.GetRDataObject<ColorData>();
            self["@color"] = color;
            return state.RbNil;
        }

        [RbInstanceMethod("flash")]
        public static RbValue Flash(RbState state, RbValue self, RbValue color, RbValue duration)
        {
            var d = self.GetRDataObject<ViewportData>();
            d.FlashDuration = (int)duration.ToIntUnchecked();
            d.FlashRemain = d.FlashDuration;
            if (!color.IsNil)
            {
                // Keep the stored @color wrapper and FlashColor as one instance so a later
                // `viewport.color.set(...)` still targets the live flash color.
                d.FlashColor = color.GetRDataObject<ColorData>();
                self["@color"] = color;
            }
            return state.RbNil;
        }

        [RbInstanceMethod("update")]
        public static RbValue Update(RbState state, RbValue self)
        {
            var d = self.GetRDataObject<ViewportData>();
            if (d.FlashRemain > 0)
                --d.FlashRemain;
            else
            {
                d.FlashDuration = 0;
                d.FlashRemain = 0;
            }
            return state.RbNil;
        }

        // ── helper ───────────────────────────────────────────────────────────
        private static RbValue CreateViewport(RbState state, int x, int y, int w, int h)
        {
            var toneObj = Tone.CreateTone(state, 0.0f, 0.0f, 0.0f, 0.0f);
            var colorObj = Color.CreateColor(state, 0.0f, 0.0f, 0.0f, 0.0f);
            var data = new ViewportData(state)
            {
                X = x, Y = y,
                Width = System.Math.Max(1, w),
                Height = System.Math.Max(1, h),
                Z = 0,
                Visible = true,
                Tone = toneObj.GetRDataObject<ToneData>(),
                FlashColor = colorObj.GetRDataObject<ColorData>(),
            };
            GameRenderManager.Instance.RegisterViewport(data);

            var cls = RubyScriptManager.Instance.GetClassUnderUnityModule("Viewport");
            var obj = cls.NewObjectWithRData(data);
            obj["@tone"] = toneObj;
            obj["@color"] = colorObj;
            return obj;
        }
    }
}
