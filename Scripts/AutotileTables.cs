namespace RGSSUnity;

// Autotile quarter-source rectangle tables, ported verbatim from mkxp-z
// (src/display/autotilesvx.cpp + tileatlasvx.cpp, commit 66939a31).
//
// mkxp stores 15x15 quarters at .5 pixel insets to avoid GPU texture-filter bleed.
// We composite on the CPU with exact Image.BlendRect copies, so the insets are dropped
// and the quarters snap to the exact 16px sub-tile grid (0,16,32,48,64,80) at 16x16
// (waterfall halves are 16x32). Coordinates are offsets WITHIN an autotile source block;
// the caller adds the block's atlas pixel origin.
internal static class AutotileTables
{
    internal readonly struct Rect
    {
        public readonly int X;
        public readonly int Y;
        public readonly int W;
        public readonly int H;
        public Rect(int x, int y, int w, int h) { X = x; Y = y; W = w; H = h; }
    }

    private static Rect Q(int x, int y) => new(x, y, 16, 16);   // quarter sub-tile
    private static Rect HV(int x, int y) => new(x, y, 16, 32);  // waterfall half-column

    // A-type: 48 shapes x 4 quarters (TL, TR, BL, BR). 192 entries.
    public static readonly Rect[] A =
    {
        Q(32,64), Q(16,64), Q(32,48), Q(16,48), // 0
        Q(32, 0), Q(16,64), Q(32,48), Q(16,48), // 1
        Q(32,64), Q(48, 0), Q(32,48), Q(16,48), // 2
        Q(32, 0), Q(48, 0), Q(32,48), Q(16,48), // 3
        Q(32,64), Q(16,64), Q(32,48), Q(48,16), // 4
        Q(32, 0), Q(16,64), Q(32,48), Q(48,16), // 5
        Q(32,64), Q(48, 0), Q(32,48), Q(48,16), // 6
        Q(32, 0), Q(48, 0), Q(32,48), Q(48,16), // 7
        Q(32,64), Q(16,64), Q(32,16), Q(16,48), // 8
        Q(32, 0), Q(16,64), Q(32,16), Q(16,48), // 9
        Q(32,64), Q(48, 0), Q(32,16), Q(16,48), // 10
        Q(32, 0), Q(48, 0), Q(32,16), Q(16,48), // 11
        Q(32,64), Q(16,64), Q(32,16), Q(48,16), // 12
        Q(32, 0), Q(16,64), Q(32,16), Q(48,16), // 13
        Q(32,64), Q(48, 0), Q(32,16), Q(48,16), // 14
        Q(32, 0), Q(48, 0), Q(32,16), Q(48,16), // 15
        Q( 0,64), Q(16,64), Q( 0,48), Q(16,48), // 16
        Q( 0,64), Q(48, 0), Q( 0,48), Q(16,48), // 17
        Q( 0,64), Q(16,64), Q( 0,48), Q(48,16), // 18
        Q( 0,64), Q(48, 0), Q( 0,48), Q(48,16), // 19
        Q(32,32), Q(16,32), Q(32,48), Q(16,48), // 20
        Q(32,32), Q(16,32), Q(32,48), Q(48,16), // 21
        Q(32,32), Q(16,32), Q(32,16), Q(16,48), // 22
        Q(32,32), Q(16,32), Q(32,16), Q(48,16), // 23
        Q(32,64), Q(48,64), Q(32,48), Q(48,48), // 24
        Q(32,64), Q(48,64), Q(32,16), Q(48,48), // 25
        Q(32, 0), Q(48,64), Q(32,48), Q(48,48), // 26
        Q(32, 0), Q(48,64), Q(32,16), Q(48,48), // 27
        Q(32,64), Q(16,64), Q(32,80), Q(16,80), // 28
        Q(32, 0), Q(16,64), Q(32,80), Q(16,80), // 29
        Q(32,64), Q(48, 0), Q(32,80), Q(16,80), // 30
        Q(32, 0), Q(48, 0), Q(32,80), Q(16,80), // 31
        Q( 0,64), Q(48,64), Q( 0,48), Q(48,48), // 32
        Q(32,32), Q(16,32), Q(32,80), Q(16,80), // 33
        Q( 0,32), Q(16,32), Q( 0,48), Q(16,48), // 34
        Q( 0,32), Q(16,32), Q( 0,48), Q(48,16), // 35
        Q(32,32), Q(48,32), Q(32,48), Q(48,48), // 36
        Q(32,32), Q(48,32), Q(32,16), Q(48,48), // 37
        Q(32,64), Q(48,64), Q(32,80), Q(48,80), // 38
        Q(32, 0), Q(48,64), Q(32,80), Q(48,80), // 39
        Q( 0,64), Q(16,64), Q( 0,80), Q(16,80), // 40
        Q( 0,64), Q(48, 0), Q( 0,80), Q(16,80), // 41
        Q( 0,32), Q(48,32), Q( 0,48), Q(48,48), // 42
        Q( 0,32), Q(16,32), Q( 0,80), Q(16,80), // 43
        Q( 0,64), Q(48,64), Q( 0,80), Q(48,80), // 44
        Q(32,32), Q(48,32), Q(32,80), Q(48,80), // 45
        Q( 0,32), Q(48,32), Q( 0,80), Q(48,80), // 46
        Q( 0, 0), Q(16, 0), Q( 0,16), Q(16,16), // 47
    };

    // Wall-type: 16 shapes x 4 quarters. 64 entries.
    public static readonly Rect[] B =
    {
        Q(32,32), Q(16,32), Q(32,16), Q(16,16), // 0
        Q( 0,32), Q(16,32), Q( 0,16), Q(16,16), // 1
        Q(32, 0), Q(16, 0), Q(32,16), Q(16,16), // 2
        Q( 0, 0), Q(16, 0), Q( 0,16), Q(16,16), // 3
        Q(32,32), Q(48,32), Q(32,16), Q(48,16), // 4
        Q( 0,32), Q(48,32), Q( 0,16), Q(48,16), // 5
        Q(32, 0), Q(48, 0), Q(32,16), Q(48,16), // 6
        Q( 0, 0), Q(48, 0), Q( 0,16), Q(48,16), // 7
        Q(32,32), Q(16,32), Q(32,48), Q(16,48), // 8
        Q( 0,32), Q(16,32), Q( 0,48), Q(16,48), // 9
        Q(32, 0), Q(16, 0), Q(32,48), Q(16,48), // 10
        Q( 0, 0), Q(16, 0), Q( 0,48), Q(16,48), // 11
        Q(32,32), Q(48,32), Q(32,48), Q(48,48), // 12
        Q( 0,32), Q(48,32), Q( 0,48), Q(48,48), // 13
        Q(32, 0), Q(48, 0), Q(32,48), Q(48,48), // 14
        Q( 0, 0), Q(48, 0), Q( 0,48), Q(48,48), // 15
    };

    // Waterfall: 4 shapes x 2 half-columns (left, right). 8 entries.
    public static readonly Rect[] C =
    {
        HV(32,0), HV(16,0), // 0
        HV( 0,0), HV(16,0), // 1
        HV(32,0), HV(48,0), // 2
        HV( 0,0), HV(48,0), // 3
    };
}
