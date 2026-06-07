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

            var colorObj = Color.CreateColor(state, 0.0f, 0.0f, 0.0f, 0.0f);
            var outColorObj = Color.CreateColor(state, 0.0f, 0.0f, 0.0f, 0.0f);
            var fontData = new FontData(state)
            {
                Names = nameArr,
                Size = (int)fontSize,
                Color = colorObj.GetRDataObject<ColorData>(),
                OutlineColor = outColorObj.GetRDataObject<ColorData>(),
            };

            var res = CreateFont(state, fontData);
            // Store the Color wrappers so RGSS3 `font.color.set(...)` (Window_Base#change_color,
            // the primary text-colour mechanism) mutates the live FontData.Color.
            res["@color"] = colorObj;
            res["@out_color"] = outColorObj;
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
            // Return the stored Color wrapper so RGSS3 `font.color.set(...)` mutates the
            // live FontData.Color the text renderer reads.
            var stored = self["@color"];
            if (!stored.IsNil)
                return stored;

            var fontData = self.GetRDataObject<FontData>();
            var colorObj = Color.CreateColor(state,
                fontData.Color.R * 255.0f, fontData.Color.G * 255.0f,
                fontData.Color.B * 255.0f, fontData.Color.A * 255.0f);
            fontData.Color = colorObj.GetRDataObject<ColorData>();
            self["@color"] = colorObj;
            return colorObj;
        }

        [RbInstanceMethod("color=")]
        public static RbValue SetColor(RbState state, RbValue self, RbValue color)
        {
            var fontData = self.GetRDataObject<FontData>();
            var colorData = color.GetRDataObject<ColorData>();

            fontData.Color = colorData;
            self["@color"] = color;
            return state.RbNil;
        }

        [RbInstanceMethod("out_color")]
        public static RbValue GetOutColor(RbState state, RbValue self)
        {
            var stored = self["@out_color"];
            if (!stored.IsNil)
                return stored;

            var fontData = self.GetRDataObject<FontData>();
            var colorObj = Color.CreateColor(state,
                fontData.OutlineColor.R * 255.0f, fontData.OutlineColor.G * 255.0f,
                fontData.OutlineColor.B * 255.0f, fontData.OutlineColor.A * 255.0f);
            fontData.OutlineColor = colorObj.GetRDataObject<ColorData>();
            self["@out_color"] = colorObj;
            return colorObj;
        }

        [RbInstanceMethod("out_color=")]
        public static RbValue SetOutColor(RbState state, RbValue self, RbValue outColor)
        {
            var fontData = self.GetRDataObject<FontData>();
            var colorData = outColor.GetRDataObject<ColorData>();

            fontData.OutlineColor = colorData;
            self["@out_color"] = outColor;
            return state.RbNil;
        }
    }
}
