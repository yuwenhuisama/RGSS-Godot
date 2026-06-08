using MRuby.Library.Language;

namespace RGSSUnity.RubyClasses
{
    public class ViewportData : RubyData
    {
        // The viewport's screen rect (position + clip size) is stored in a single live
        // RectData so the Ruby-side `Viewport#rect` wrapper can mutate it in place
        // (stock RMVA does `viewport.rect.y = N`). X/Y/Width/Height forward to it so the
        // renderer keeps reading flat fields.
        public RectData Rect = null!;

        public int X { get => this.Rect.X; set => this.Rect.X = value; }
        public int Y { get => this.Rect.Y; set => this.Rect.Y = value; }
        public int Width { get => this.Rect.Width; set => this.Rect.Width = value; }
        public int Height { get => this.Rect.Height; set => this.Rect.Height = value; }

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
