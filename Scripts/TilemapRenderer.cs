using Godot;
using RGSSUnity.RubyClasses;

namespace RGSSUnity;

// RGSS3 (RPG Maker VX Ace) tile decoding + CPU compositing, ported from the algorithm
// in mkxp-z (src/display/gl/tileatlasvx.cpp + autotilesvx.cpp). Given a tile ID and the
// 9 tileset bitmaps, it blends the correct 32x32 image into a destination Image at a
// pixel position, handling plain tiles (A5/B/C/D/E) and the 48-variant autotiles (A1-A4).
internal static class TilemapRenderer
{
    public const int TileSize = 32;
    private const int Half = 16;

    // ── Tile-ID range constants (mkxp-z, hex) ────────────────────────────────────
    private const int IdBcdeMax = 0x0400;   // 1..1023
    private const int IdA5Base  = 0x0600;   // 1536
    private const int IdA5Max   = 0x0680;   // 1663
    private const int IdA1Base  = 0x0800;   // 2048
    private const int IdA2Base  = 0x0B00;   // 2816
    private const int IdA3Base  = 0x1100;   // 4352
    private const int IdA4Base  = 0x1700;   // 5888
    private const int IdA4Max   = 0x2000;   // 8191

    public const int OverPlayerFlag = 0x10;

    // Bitmap slot indices into TilemapData.Bitmaps.
    private const int BmA1 = 0, BmA2 = 1, BmA3 = 2, BmA4 = 3, BmA5 = 4, BmB = 5;

    // Quarter order: TopLeft, TopRight, BottomLeft, BottomRight.
    private static readonly Vector2I[] QuarterDst =
    {
        new(0, 0), new(Half, 0), new(0, Half), new(Half, Half),
    };

    // ── Public entry: blend one tile id into dst at (px,py) ───────────────────────
    // Returns true if anything was drawn. animA/animC are 0..2 autotile animation frames.
    public static bool DrawTile(Image dst, int px, int py, int tileId, BitmapData?[] bitmaps, int animA, int animC)
    {
        if (tileId <= 0)
            return false;

        if (tileId < IdBcdeMax)
            return DrawBcde(dst, px, py, tileId, bitmaps);
        if (tileId >= IdA5Base && tileId < IdA5Max)
            return DrawA5(dst, px, py, tileId, bitmaps);
        if (tileId >= IdA1Base && tileId < IdA2Base)
            return DrawA1(dst, px, py, tileId, bitmaps, animA, animC);
        if (tileId >= IdA2Base && tileId < IdA3Base)
            return DrawA2(dst, px, py, tileId, bitmaps);
        if (tileId >= IdA3Base && tileId < IdA4Base)
            return DrawA3(dst, px, py, tileId, bitmaps);
        if (tileId >= IdA4Base && tileId < IdA4Max)
            return DrawA4(dst, px, py, tileId, bitmaps);

        return false;
    }

    // ── Plain tiles ───────────────────────────────────────────────────────────────
    // B/C/D/E: 0..1023, 8 cols per half-page, 16 rows, alternating half-pages across sheets.
    private static bool DrawBcde(Image dst, int px, int py, int id, BitmapData?[] bitmaps)
    {
        var ox = id % 8;
        var oy = (id / 8) % 16;
        var ob = id / (8 * 16);                 // 0..7 → B-left,B-right,C-left,...
        ox += (ob % 2) * 8;
        var bmpIndex = BmB + ob / 2;            // 5=B,6=C,7=D,8=E
        var src = GetImage(bitmaps, bmpIndex);
        if (src is null)
            return false;
        return Blend(dst, src, ox * TileSize, oy * TileSize, px, py, TileSize, TileSize);
    }

    // A5: 1536..1663, plain non-autotile, 8 cols x 16 rows.
    private static bool DrawA5(Image dst, int px, int py, int id, BitmapData?[] bitmaps)
    {
        id -= IdA5Base;
        var ox = id % 8;
        var oy = id / 8;
        var src = GetImage(bitmaps, BmA5);
        if (src is null)
            return false;
        return Blend(dst, src, ox * TileSize, oy * TileSize, px, py, TileSize, TileSize);
    }

    // ── Autotiles ───────────────────────────────────────────────────────────────
    // A1 (animated water): 16 autotile slots, with waterfall sub-types.
    private static bool DrawA1(Image dst, int px, int py, int id, BitmapData?[] bitmaps, int animA, int animC)
    {
        id -= IdA1Base;                          // 0..767
        var pattern = id % 48;
        var slot = id / 48;                      // 0..15
        var src = GetImage(bitmaps, BmA1);
        if (src is null)
            return false;

        // Origin (in tile units) of each A1 autotile slot's 2x3 block within TileA1.
        // -1 marks the waterfall slots (odd slots from 5 on). Animated slots shift by
        // animA*2 tile-cols (each frame block is 2 tiles to the right).
        var (ox, oy, waterfall) = A1SlotOrigin(slot);
        if (waterfall)
        {
            var wox = oy + animC; // waterfall animates vertically by 1 tile-row per frame
            return DrawWaterfall(dst, src, ox, wox, pattern, px, py);
        }

        var blockX = ox + animA * 2;
        return DrawAutotileA(dst, src, blockX * TileSize, oy * TileSize, pattern, px, py);
    }

    private static (int ox, int oy, bool waterfall) A1SlotOrigin(int slot)
    {
        // Derived from mkxp-z onTileA1 atOrig[] (tile units).
        return slot switch
        {
            0 => (0, 0, false),
            1 => (0, 3, false),
            2 => (6, 0, false),   // "unanimated" cols 6-7 used as a stable block
            3 => (6, 3, false),
            4 => (8, 0, false),
            5 => (0, 0, true),
            6 => (8, 3, false),
            7 => (0, 3, true),
            8 => (0, 6, false),
            9 => (0, 6, true),
            10 => (0, 9, false),
            11 => (0, 9, true),
            12 => (8, 6, false),
            13 => (8, 6, true),
            14 => (8, 9, false),
            _ => (8, 9, true),
        };
    }

    // A2 (ground): 32 slots, 8 cols x 4 rows, each slot 2x3 tiles.
    private static bool DrawA2(Image dst, int px, int py, int id, BitmapData?[] bitmaps)
    {
        id -= IdA2Base;
        var pattern = id % 48;
        var slot = id / 48;                      // 0..31
        var src = GetImage(bitmaps, BmA2);
        if (src is null)
            return false;
        var bx = (slot % 8) * 2;
        var by = (slot / 8) * 3;
        return DrawAutotileA(dst, src, bx * TileSize, by * TileSize, pattern, px, py);
    }

    // A3 (buildings): wall-type autotiles, 8 cols x 4 rows, each slot 2x2 tiles.
    private static bool DrawA3(Image dst, int px, int py, int id, BitmapData?[] bitmaps)
    {
        id -= IdA3Base;
        var pattern = id % 48;
        var slot = id / 48;
        var src = GetImage(bitmaps, BmA3);
        if (src is null)
            return false;
        var bx = (slot % 8) * 2;
        var by = (slot / 8) * 2;
        return DrawAutotileWall(dst, src, bx * TileSize, by * TileSize, pattern, px, py);
    }

    // A4 (walls): alternating A-type (3-row) and wall-type (2-row) row groups.
    private static bool DrawA4(Image dst, int px, int py, int id, BitmapData?[] bitmaps)
    {
        id -= IdA4Base;
        var pattern = id % 48;
        var slot = id / 48;
        var src = GetImage(bitmaps, BmA4);
        if (src is null)
            return false;

        // Row-group Y offsets (tile units) and whether each group is A-type or wall-type.
        int[] offY = { 0, 3, 5, 8, 10, 13 };
        var group = slot / 8;                    // 0..5
        var bx = (slot % 8) * 2;
        var by = offY[group];
        if (group % 2 == 0)
            return DrawAutotileA(dst, src, bx * TileSize, by * TileSize, pattern, px, py);
        return DrawAutotileWall(dst, src, bx * TileSize, by * TileSize, pattern, px, py);
    }

    // ── Autotile quarter assembly ─────────────────────────────────────────────────
    // A-type: 48 shapes x 4 quarters. originX/Y = pixel origin of the 64x96 autotile block.
    private static bool DrawAutotileA(Image dst, BitmapData src, int originX, int originY, int pattern, int px, int py)
    {
        var img = src.Image;
        if (img is null)
            return false;
        var drew = false;
        for (var q = 0; q < 4; q++)
        {
            var r = AutotileTables.A[pattern * 4 + q];
            drew |= Blend(dst, src, originX + r.X, originY + r.Y, px + QuarterDst[q].X, py + QuarterDst[q].Y, Half, Half);
        }
        return drew;
    }

    // Wall-type: 16 shapes x 4 quarters; patterns >= 16 draw nothing.
    private static bool DrawAutotileWall(Image dst, BitmapData src, int originX, int originY, int pattern, int px, int py)
    {
        if (pattern >= 16)
            return false;
        var drew = false;
        for (var q = 0; q < 4; q++)
        {
            var r = AutotileTables.B[pattern * 4 + q];
            drew |= Blend(dst, src, originX + r.X, originY + r.Y, px + QuarterDst[q].X, py + QuarterDst[q].Y, Half, Half);
        }
        return drew;
    }

    // Waterfall (A1 sub-type): 4 shapes x 2 half-columns (full tile height).
    private static bool DrawWaterfall(Image dst, BitmapData src, int oxTiles, int oyTiles, int pattern, int px, int py)
    {
        var shape = pattern % 4;
        var baseX = oxTiles * TileSize;
        var baseY = oyTiles * TileSize;
        var drew = false;
        for (var h = 0; h < 2; h++)
        {
            var r = AutotileTables.C[shape * 2 + h];
            drew |= Blend(dst, src, baseX + r.X, baseY + r.Y, px + h * Half, py, Half, TileSize);
        }
        return drew;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────────
    private static BitmapData? GetImage(BitmapData?[] bitmaps, int index)
    {
        if (index < 0 || index >= bitmaps.Length)
            return null;
        var b = bitmaps[index];
        return b is { Disposed: false, Image: not null } ? b : null;
    }

    // Alpha-composite a source sub-rect onto dst at (dstX,dstY). Clamps to source bounds.
    private static bool Blend(Image dst, BitmapData src, int srcX, int srcY, int dstX, int dstY, int w, int h)
    {
        var img = src.Image;
        if (img is null)
            return false;

        var clamped = new Rect2I(srcX, srcY, w, h)
            .Intersection(new Rect2I(0, 0, img.GetWidth(), img.GetHeight()));
        if (clamped.Size.X <= 0 || clamped.Size.Y <= 0)
            return false;

        var srcImg = img;
        if (srcImg.GetFormat() != Image.Format.Rgba8)
        {
            srcImg = (Image)img.Duplicate();
            srcImg.Convert(Image.Format.Rgba8);
        }

        dst.BlendRect(srcImg, clamped, new Vector2I(dstX, dstY));
        return true;
    }
}
