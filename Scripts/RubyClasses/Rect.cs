using MRuby.Library.Language;
using MRuby.Library.Mapper;
using RGSSGodot;

namespace RGSSUnity.RubyClasses
{
    public class RectData : RubyData
    {
        public int X;
        public int Y;
        public int Width;
        public int Height;

        public RectData(RbState state) : base(state)
        {
        }
    }

    [RbClass("Rect", "Object", "Unity")]
    public static class Rect
    {
        public static RbValue CreateRect(RbState state, int xVal, int yVal, int wVal, int hVal)
        {
            var rect = new RectData(state)
            {
                X = xVal,
                Y = yVal,
                Width = wVal,
                Height = hVal,
            };
            var cls = RubyScriptManager.Instance.GetClassUnderUnityModule("Rect");
            var res = cls.NewObjectWithRData(rect);
            return res;
        }

        [RbClassMethod("new_xywh")]
        public static RbValue NewRect(RbState state, RbValue self, RbValue x, RbValue y, RbValue w, RbValue h)
        {
            var xVal = (int)x.ToIntUnchecked();
            var yVal = (int)y.ToIntUnchecked();
            var wVal = (int)w.ToIntUnchecked();
            var hVal = (int)h.ToIntUnchecked();

            var res = CreateRect(state, xVal, yVal, wVal, hVal);
            return res;
        }

        [RbInstanceMethod("set_xywh")]
        public static RbValue Set(RbState state, RbValue self, RbValue x, RbValue y, RbValue w, RbValue h)
        {
            var xVal = (int)x.ToIntUnchecked();
            var yVal = (int)y.ToIntUnchecked();
            var wVal = (int)w.ToIntUnchecked();
            var hVal = (int)h.ToIntUnchecked();

            var rectData = self.GetRDataObject<RectData>();
            rectData.X = xVal;
            rectData.Y = yVal;
            rectData.Width = wVal;
            rectData.Height = hVal;
            return state.RbNil;
        }

        [RbInstanceMethod("x")]
        public static RbValue GetX(RbState state, RbValue self)
        {
            var rectData = self.GetRDataObject<RectData>();
            return rectData.X.ToValue(state);
        }

        [RbInstanceMethod("x=")]
        public static RbValue SetX(RbState state, RbValue self, RbValue x)
        {
            var xVal = (int)x.ToIntUnchecked();
            var rectData = self.GetRDataObject<RectData>();
            rectData.X = xVal;
            return state.RbNil;
        }

        [RbInstanceMethod("y")]
        public static RbValue GetY(RbState state, RbValue self)
        {
            var rectData = self.GetRDataObject<RectData>();
            return rectData.Y.ToValue(state);
        }

        [RbInstanceMethod("y=")]
        public static RbValue SetY(RbState state, RbValue self, RbValue y)
        {
            var yVal = (int)y.ToIntUnchecked();
            var rectData = self.GetRDataObject<RectData>();
            rectData.Y = yVal;
            return state.RbNil;
        }

        [RbInstanceMethod("width")]
        public static RbValue GetW(RbState state, RbValue self)
        {
            var rectData = self.GetRDataObject<RectData>();
            return rectData.Width.ToValue(state);
        }

        [RbInstanceMethod("width=")]
        public static RbValue SetW(RbState state, RbValue self, RbValue w)
        {
            var wVal = (int)w.ToIntUnchecked();
            var rectData = self.GetRDataObject<RectData>();
            rectData.Width = wVal;
            return state.RbNil;
        }

        [RbInstanceMethod("height")]
        public static RbValue GetH(RbState state, RbValue self)
        {
            var rectData = self.GetRDataObject<RectData>();
            return rectData.Height.ToValue(state);
        }

        [RbInstanceMethod("height=")]
        public static RbValue SetH(RbState state, RbValue self, RbValue h)
        {
            var hVal = (int)h.ToIntUnchecked();
            var rectData = self.GetRDataObject<RectData>();
            rectData.Height = hVal;
            return state.RbNil;
        }
    }
}
