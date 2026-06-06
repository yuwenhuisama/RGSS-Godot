using System.Linq;
using MRuby.Library.Language;
using MRuby.Library.Mapper;
using RGSSGodot;

namespace RGSSUnity.RubyClasses
{
    public class FontData : RubyData
    {
        public string[] Names = [];
        public int Size;
        public bool Bold;
        public bool Italic;
        public bool Shadow;
        public bool Outline;
        public ColorData Color = null!;
        public ColorData OutlineColor = null!;

        public FontData(RbState state) : base(state)
        {
        }
    }

    [RbClass("Font", "Object", "Unity")]
    public static class Font
    {
        private static RbValue CreateFont(RbState state, FontData fontData)
        {
            var cls = RubyScriptManager.Instance.GetClassUnderUnityModule("Font");
            var res = cls.NewObjectWithRData(fontData);
            return res;
        }

        [RbClassMethod("new_ns")]
        public static RbValue NewFont(RbState state, RbValue self, RbValue name, RbValue size)
        {
            var fontSize = size.ToIntUnchecked();

            var nameArr = name
                .ToArray()
                .Select(v => v.ToStringUnchecked())
                .ToArray();

            var fontData = new FontData(state)
            {
                Names = nameArr,
                Size = (int)fontSize,
                Color = new ColorData(state),
                OutlineColor = new ColorData(state),
            };

            var res = CreateFont(state, fontData);
            return res;
        }

        [RbInstanceMethod("name")]
        public static RbValue GetName(RbState state, RbValue self)
        {
            var fontData = self.GetRDataObject<FontData>();
            return fontData.Names.Select(v => v.ToValue(state)).ToRbArray(state).ToValue();
        }

        [RbInstanceMethod("name=")]
        public static RbValue SetName(RbState state, RbValue self, RbValue name)
        {
            var fontData = self.GetRDataObject<FontData>();
            var nameArr = name.ToArrayUnchecked();
            fontData.Names = nameArr.Select(v => v.ToStringUnchecked()).ToArray();

            return state.RbNil;
        }

        [RbInstanceMethod("size")]
        public static RbValue GetSize(RbState state, RbValue self)
        {
            var fontData = self.GetRDataObject<FontData>();
            return fontData.Size.ToValue(state);
        }

        [RbInstanceMethod("size=")]
        public static RbValue SetSize(RbState state, RbValue self, RbValue size)
        {
            var fontData = self.GetRDataObject<FontData>();
            fontData.Size = (int)size.ToInt();
            return state.RbNil;
        }

        [RbInstanceMethod("bold")]
        public static RbValue GetBold(RbState state, RbValue self)
        {
            var fontData = self.GetRDataObject<FontData>();
            return fontData.Bold.ToValue(state);
        }

        [RbInstanceMethod("bold=")]
        public static RbValue SetBold(RbState state, RbValue self, RbValue bold)
        {
            var fontData = self.GetRDataObject<FontData>();
            fontData.Bold = bold.IsTrue;
            return state.RbNil;
        }

        [RbInstanceMethod("italic")]
        public static RbValue GetItalic(RbState state, RbValue self)
        {
            var fontData = self.GetRDataObject<FontData>();
            return fontData.Italic.ToValue(state);
        }

        [RbInstanceMethod("italic=")]
        public static RbValue SetItalic(RbState state, RbValue self, RbValue italic)
        {
            var fontData = self.GetRDataObject<FontData>();
            fontData.Italic = italic.IsTrue;
            return state.RbNil;
        }

        [RbInstanceMethod("shadow")]
        public static RbValue GetShadow(RbState state, RbValue self)
        {
            var fontData = self.GetRDataObject<FontData>();
            return fontData.Shadow.ToValue(state);
        }

        [RbInstanceMethod("shadow=")]
        public static RbValue SetShadow(RbState state, RbValue self, RbValue shadow)
        {
            var fontData = self.GetRDataObject<FontData>();
            fontData.Shadow = shadow.IsTrue;
            return state.RbNil;
        }

        [RbInstanceMethod("outline")]
        public static RbValue GetOutline(RbState state, RbValue self)
        {
            var fontData = self.GetRDataObject<FontData>();
            return fontData.Outline.ToValue(state);
        }

        [RbInstanceMethod("outline=")]
        public static RbValue SetOutline(RbState state, RbValue self, RbValue outline)
        {
            var fontData = self.GetRDataObject<FontData>();
            fontData.Outline = outline.IsTrue;
            return state.RbNil;
        }

        [RbInstanceMethod("color")]
        public static RbValue GetColor(RbState state, RbValue self)
        {
            var fontData = self.GetRDataObject<FontData>();
            var color = Color.NewColor(state,
                state.RbNil,
                ((int)(fontData.Color.R * 255)).ToValue(state),
                ((int)(fontData.Color.G * 255)).ToValue(state),
                ((int)(fontData.Color.B * 255)).ToValue(state),
                ((int)(fontData.Color.A * 255)).ToValue(state));
            return color;
        }

        [RbInstanceMethod("color=")]
        public static RbValue SetColor(RbState state, RbValue self, RbValue color)
        {
            var fontData = self.GetRDataObject<FontData>();
            var colorData = color.GetRDataObject<ColorData>();

            fontData.Color = colorData;
            return state.RbNil;
        }

        [RbInstanceMethod("out_color")]
        public static RbValue GetOutColor(RbState state, RbValue self)
        {
            var fontData = self.GetRDataObject<FontData>();
            var color = Color.NewColor(state,
                state.RbNil,
                ((int)(fontData.OutlineColor.R * 255)).ToValue(state),
                ((int)(fontData.OutlineColor.G * 255)).ToValue(state),
                ((int)(fontData.OutlineColor.B * 255)).ToValue(state),
                ((int)(fontData.OutlineColor.A * 255)).ToValue(state));
            return color;
        }

        [RbInstanceMethod("out_color=")]
        public static RbValue SetOutColor(RbState state, RbValue self, RbValue outColor)
        {
            var fontData = self.GetRDataObject<FontData>();
            var colorData = outColor.GetRDataObject<ColorData>();

            fontData.OutlineColor = colorData;
            return state.RbNil;
        }
    }
}
