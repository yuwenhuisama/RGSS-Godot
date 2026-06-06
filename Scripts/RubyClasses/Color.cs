using System;
using MRuby.Library.Language;
using MRuby.Library.Mapper;
using RGSSGodot;

namespace RGSSUnity.RubyClasses
{
    public class ColorData : RubyData
    {
        public float R;
        public float G;
        public float B;
        public float A;

        public ColorData(RbState state) : base(state)
        {
        }
    }

    [RbClass("Color", "Object", "Unity")]
    public static class Color
    {
        public static RbValue CreateColor(RbState state, float rVal, float gVal, float bVal, float aVal)
        {
            try
            {
                var stub = new ColorData(state)
                {
                    R = rVal / 255.0f,
                    G = gVal / 255.0f,
                    B = bVal / 255.0f,
                    A = aVal / 255.0f,
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

                var res = CreateColor(state, (float)rVal, (float)gVal, (float)bVal, (float)aVal);
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
            colorData.R = (float)rVal;
            colorData.G = (float)gVal;
            colorData.B = (float)bVal;
            colorData.A = (float)aVal;
            return state.RbNil;
        }

        [RbInstanceMethod("red")]
        public static RbValue GetR(RbState state, RbValue self)
        {
            var colorData = self.GetRDataObject<ColorData>();
            return (colorData.R * 255.0f).ToValue(state);
        }

        [RbInstanceMethod("red=")]
        public static RbValue SetR(RbState state, RbValue self, RbValue r)
        {
            var rVal = r.IsInt ? r.ToIntUnchecked() : r.ToFloatUnchecked();
            var colorData = self.GetRDataObject<ColorData>();
            colorData.R = (float)rVal / 255.0f;
            return state.RbNil;
        }

        [RbInstanceMethod("green")]
        public static RbValue GetG(RbState state, RbValue self)
        {
            var colorData = self.GetRDataObject<ColorData>();
            return (colorData.G * 255.0f).ToValue(state);
        }

        [RbInstanceMethod("green=")]
        public static RbValue SetG(RbState state, RbValue self, RbValue g)
        {
            var gVal = g.IsInt ? g.ToIntUnchecked() : g.ToFloatUnchecked();
            var colorData = self.GetRDataObject<ColorData>();
            colorData.G = (float)gVal / 255.0f;
            return state.RbNil;
        }

        [RbInstanceMethod("blue")]
        public static RbValue GetB(RbState state, RbValue self)
        {
            var colorData = self.GetRDataObject<ColorData>();
            return (colorData.B * 255.0f).ToValue(state);
        }

        [RbInstanceMethod("blue=")]
        public static RbValue SetB(RbState state, RbValue self, RbValue b)
        {
            var bVal = b.IsInt ? b.ToIntUnchecked() : b.ToFloatUnchecked();
            var colorData = self.GetRDataObject<ColorData>();
            colorData.B = (float)bVal / 255.0f;
            return state.RbNil;
        }

        [RbInstanceMethod("alpha")]
        public static RbValue GetA(RbState state, RbValue self)
        {
            var colorData = self.GetRDataObject<ColorData>();
            return (colorData.A * 255.0f).ToValue(state);
        }

        [RbInstanceMethod("alpha=")]
        public static RbValue SetA(RbState state, RbValue self, RbValue a)
        {
            var aVal = a.IsInt ? a.ToIntUnchecked() : a.ToFloatUnchecked();
            var colorData = self.GetRDataObject<ColorData>();
            colorData.A = (float)aVal / 255.0f;
            return state.RbNil;
        }
    }
}
