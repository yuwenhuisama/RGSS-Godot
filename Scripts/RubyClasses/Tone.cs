using MRuby.Library.Language;
using MRuby.Library.Mapper;
using RGSSGodot;

namespace RGSSUnity.RubyClasses
{
    public class ToneData : RubyData
    {
        public double RedValue;
        public double GreenValue;
        public double BlueValue;
        public double GrayValue;

        public float Red
        {
            get => (float)(RedValue / 255.0);
        }

        public float Green
        {
            get => (float)(GreenValue / 255.0);
        }

        public float Blue
        {
            get => (float)(BlueValue / 255.0);
        }

        public float Gray
        {
            get => (float)(GrayValue / 255.0);
        }

        public ToneData(RbState state) : base(state)
        {
        }
    }

    [RbClass("Tone", "Object", "Unity")]
    public static class Tone
    {
        public static RbValue CreateTone(RbState state, double rVal, double gVal, double bVal, double grayVal)
        {
            var tone = new ToneData(state)
            {
                RedValue = rVal,
                GreenValue = gVal,
                BlueValue = bVal,
                GrayValue = grayVal,
            };
            var cls = RubyScriptManager.Instance.GetClassUnderUnityModule("Tone");
            var res = cls.NewObjectWithRData(tone);
            return res;
        }

        [RbClassMethod("new_rgbg")]
        public static RbValue NewTone(RbState state, RbValue self, RbValue r, RbValue g, RbValue b, RbValue gray)
        {
            var rVal = r.IsInt ? r.ToIntUnchecked() : r.ToFloatUnchecked();
            var gVal = g.IsInt ? g.ToIntUnchecked() : g.ToFloatUnchecked();
            var bVal = b.IsInt ? b.ToIntUnchecked() : b.ToFloatUnchecked();
            var grayVal = gray.IsInt ? gray.ToIntUnchecked() : gray.ToFloatUnchecked();

            var res = CreateTone(state, rVal, gVal, bVal, grayVal);
            return res;
        }

        [RbInstanceMethod("set_rgbg")]
        public static RbValue SetRgbg(RbState state, RbValue self, RbValue r, RbValue g, RbValue b, RbValue gray)
        {
            var rVal = r.IsInt ? r.ToIntUnchecked() : r.ToFloatUnchecked();
            var gVal = g.IsInt ? g.ToIntUnchecked() : g.ToFloatUnchecked();
            var bVal = b.IsInt ? b.ToIntUnchecked() : b.ToFloatUnchecked();
            var grayVal = gray.IsInt ? gray.ToIntUnchecked() : gray.ToFloatUnchecked();

            var toneData = self.GetRDataObject<ToneData>();
            toneData.RedValue = rVal;
            toneData.GreenValue = gVal;
            toneData.BlueValue = bVal;
            toneData.GrayValue = grayVal;
            return state.RbNil;
        }

        [RbInstanceMethod("red")]
        public static RbValue GetR(RbState state, RbValue self)
        {
            var toneData = self.GetRDataObject<ToneData>();
            return toneData.RedValue.ToValue(state);
        }

        [RbInstanceMethod("red=")]
        public static RbValue SetR(RbState state, RbValue self, RbValue r)
        {
            var rVal = r.IsInt ? r.ToIntUnchecked() : r.ToFloatUnchecked();
            var toneData = self.GetRDataObject<ToneData>();
            toneData.RedValue = rVal;
            return state.RbNil;
        }

        [RbInstanceMethod("green")]
        public static RbValue GetG(RbState state, RbValue self)
        {
            var toneData = self.GetRDataObject<ToneData>();
            return toneData.GreenValue.ToValue(state);
        }

        [RbInstanceMethod("green=")]
        public static RbValue SetG(RbState state, RbValue self, RbValue g)
        {
            var gVal = g.IsInt ? g.ToIntUnchecked() : g.ToFloatUnchecked();
            var toneData = self.GetRDataObject<ToneData>();
            toneData.GreenValue = gVal;
            return state.RbNil;
        }

        [RbInstanceMethod("blue")]
        public static RbValue GetB(RbState state, RbValue self)
        {
            var toneData = self.GetRDataObject<ToneData>();
            return toneData.BlueValue.ToValue(state);
        }

        [RbInstanceMethod("blue=")]
        public static RbValue SetB(RbState state, RbValue self, RbValue b)
        {
            var bVal = b.IsInt ? b.ToIntUnchecked() : b.ToFloatUnchecked();
            var toneData = self.GetRDataObject<ToneData>();
            toneData.BlueValue = bVal;
            return state.RbNil;
        }

        [RbInstanceMethod("gray")]
        public static RbValue GetGray(RbState state, RbValue self)
        {
            var toneData = self.GetRDataObject<ToneData>();
            return toneData.GrayValue.ToValue(state);
        }

        [RbInstanceMethod("gray=")]
        public static RbValue SetGray(RbState state, RbValue self, RbValue gray)
        {
            var grayVal = gray.IsInt ? gray.ToIntUnchecked() : gray.ToFloatUnchecked();
            var toneData = self.GetRDataObject<ToneData>();
            toneData.GrayValue = grayVal;
            return state.RbNil;
        }
    }
}
