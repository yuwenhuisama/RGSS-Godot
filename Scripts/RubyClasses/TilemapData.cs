using Godot;
using MRuby.Library.Language;

namespace RGSSUnity.RubyClasses;

public class TilemapData : RubyData
{
    // 9 tileset bitmaps: 0=A1, 1=A2, 2=A3, 3=A4, 4=A5, 5=B, 6=C, 7=D, 8=E.
    public BitmapData?[] Bitmaps = new BitmapData?[9];

    public TableData? MapData;     // width x height x (>=3) tile-id Table
    public TableData? FlashData;   // width x height flash colours (not yet rendered)
    public TableData? Flags;       // 1D flag table indexed by tile id (0x10 = over-player)

    public ViewportData? Viewport;

    // Scroll origin in pixels. Fractional (display_x * 32) so kept as float; only the
    // tile-index derivation floors it.
    public float Ox;
    public float Oy;

    public bool Visible = true;
    public bool Disposed;

    // Autotile animation clock, advanced once per frame by Tilemap#update.
    public int AnimationTick;

    public Node2D? Node;

    // ── Compositor cache state (set by RenderTilemap) ────────────────────────
    // The chunk currently baked into the layer images, so we can skip recompositing
    // when nothing relevant changed (Oracle: recomposite only on origin/data/anim change).
    public int CachedOriginTileX = int.MinValue;
    public int CachedOriginTileY = int.MinValue;
    public int CachedAnimFrameA = -1;
    public int CachedAnimFrameC = -1;
    public ulong CachedMapDataId;
    public bool LayersDirty = true;       // force first composite

    public TilemapData(RbState state) : base(state)
    {
    }
}
