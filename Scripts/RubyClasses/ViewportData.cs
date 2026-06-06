using MRuby.Library.Language;

namespace RGSSUnity.RubyClasses
{
    public class ViewportData : RubyData
    {
        public int X, Y, Width, Height;
        public int Z;
        public int Ox, Oy;
        public bool Visible = true;
        public ToneData? Tone;
        public ColorData? FlashColor;
        public int FlashDuration;
        public int FlashRemain;
        public bool Disposed;

        public ViewportData(RbState state) : base(state) { }
    }
}
