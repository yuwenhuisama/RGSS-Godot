using System;
using MRuby.Library.Language;
using MRuby.Library.Mapper;
using RGSSGodot;

namespace RGSSUnity.RubyClasses
{
    public class ColorData : RubyData
    {
        public double RedValue;
        public double GreenValue;
        public double BlueValue;
        public double AlphaValue;

        public float R { get => (float)(RedValue / 255.0); set => RedValue = value * 255.0; }
        public float G { get => (float)(GreenValue / 255.0); set => GreenValue = value * 255.0; }
        public float B { get => (float)(BlueValue / 255.0); set => BlueValue = value * 255.0; }
        public float A { get => (float)(AlphaValue / 255.0); set => AlphaValue = value * 255.0; }

        public ColorData(RbState state) : base(state)
        {
        }
    }

    [RbClass("Color", "Object", "Unity")]
    public static class Color
    {
        public static RbValue CreateColor(RbState state, double rVal, double gVal, double bVal, double aVal)
        {
            try
            {
                var stub = new ColorData(state)
                {
                    RedValue = rVal,
                    GreenValue = gVal,
                    BlueValue = bVal,
                    AlphaValue = aVal,
                };

                var colorCls = RubyScriptManager.Instance.GetClassUnderUnityModule("Color");
                var res = colorCls.NewObjectWithRData(stub);
                return res;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"COLOR_CREATE_FAIL:{ex}");
                throw;
            }
        }

        [RbClassMethod("new_rgba")]
        public static RbValue NewColor(RbState state, RbValue self, RbValue r, RbValue g, RbValue b, RbValue a)
        {
            try
            {
                var rVal = r.IsInt ? r.ToIntUnchecked() : r.ToFloatUnchecked();
                var gVal = g.IsInt ? g.ToIntUnchecked() : g.ToFloatUnchecked();
                var bVal = b.IsInt ? b.ToIntUnchecked() : b.ToFloatUnchecked();
                var aVal = a.IsInt ? a.ToIntUnchecked() : a.ToFloatUnchecked();

                var res = CreateColor(state, rVal, gVal, bVal, aVal);
                return res;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"COLOR_NEWCOLOR_FAIL:{ex}");
                throw;
            }
        }

        [RbInstanceMethod("set_rgba")]
        public static RbValue Set(RbState state, RbValue self, RbValue r, RbValue g, RbValue b, RbValue a)
        {
            var rVal = r.IsInt ? r.ToIntUnchecked() : r.ToFloatUnchecked();
            var gVal = g.IsInt ? g.ToIntUnchecked() : g.ToFloatUnchecked();
            var bVal = b.IsInt ? b.ToIntUnchecked() : b.ToFloatUnchecked();
            var aVal = a.IsInt ? a.ToIntUnchecked() : a.ToFloatUnchecked();

            var colorData = self.GetRDataObject<ColorData>();
            colorData.RedValue = rVal;
            colorData.GreenValue = gVal;
            colorData.BlueValue = bVal;
            colorData.AlphaValue = aVal;
            return state.RbNil;
        }

        [RbInstanceMethod("red")]
        public static RbValue GetR(RbState state, RbValue self)
        {
            var colorData = self.GetRDataObject<ColorData>();
            return colorData.RedValue.ToValue(state);
        }

        [RbInstanceMethod("red=")]
        public static RbValue SetR(RbState state, RbValue self, RbValue r)
        {
            var rVal = r.IsInt ? r.ToIntUnchecked() : r.ToFloatUnchecked();
            var colorData = self.GetRDataObject<ColorData>();
            colorData.RedValue = rVal;
            return state.RbNil;
        }

        [RbInstanceMethod("green")]
        public static RbValue GetG(RbState state, RbValue self)
        {
            var colorData = self.GetRDataObject<ColorData>();
            return colorData.GreenValue.ToValue(state);
        }

        [RbInstanceMethod("green=")]
        public static RbValue SetG(RbState state, RbValue self, RbValue g)
        {
            var gVal = g.IsInt ? g.ToIntUnchecked() : g.ToFloatUnchecked();
            var colorData = self.GetRDataObject<ColorData>();
            colorData.GreenValue = gVal;
            return state.RbNil;
        }

        [RbInstanceMethod("blue")]
        public static RbValue GetB(RbState state, RbValue self)
        {
            var colorData = self.GetRDataObject<ColorData>();
            return colorData.BlueValue.ToValue(state);
        }

        [RbInstanceMethod("blue=")]
        public static RbValue SetB(RbState state, RbValue self, RbValue b)
        {
            var bVal = b.IsInt ? b.ToIntUnchecked() : b.ToFloatUnchecked();
            var colorData = self.GetRDataObject<ColorData>();
            colorData.BlueValue = bVal;
            return state.RbNil;
        }

        [RbInstanceMethod("alpha")]
        public static RbValue GetA(RbState state, RbValue self)
        {
            var colorData = self.GetRDataObject<ColorData>();
            return colorData.AlphaValue.ToValue(state);
        }

        [RbInstanceMethod("alpha=")]
        public static RbValue SetA(RbState state, RbValue self, RbValue a)
        {
            var aVal = a.IsInt ? a.ToIntUnchecked() : a.ToFloatUnchecked();
            var colorData = self.GetRDataObject<ColorData>();
            colorData.AlphaValue = aVal;
            return state.RbNil;
        }
    }
}
