# Cursor cache quantization diagnosis (D05)

Status: **cache mechanism proven and exact**. The two-byte blue difference is
reproduced bit-for-bit by an 8-bit integer formula. The window/screen residual is
a separate composite issue; its measured scope and the exact open question are
recorded at the end.

## Symptom

`cursor_cache_reference.tsv` (3x3 corner cache) differs between the original
RGSS300 runtime and the host at exactly two pixels, blue channel only:

| pixel | original | host | delta |
|-------|----------|------|-------|
| (1,1) | 203      | 204  | +1    |
| (1,2) | 208      | 209  | +1    |

The other 34 channel values match. The fixture composites four overlapping 4x4
corner blits of a 32x32 source onto a 3x3 bitmap.

## Proven original formula

For source `(src, sa)` over destination `(dst, da)`, all channels 0..255:

    if da == 0: result = src          // empty destination takes source verbatim
    if sa == 0: result = dst          // no write
    num = 255*sa + da*(255 - sa)      // == 255 * A_exact
    a   = num // 255                  // alpha_out = floor(A_exact)
    w   = (65025*sa) // num + 1       // == floor(255*sa/A_exact) + 1
    out_c = (src_c*w + dst_c*(256 - w)) >> 8

Both guard orders are measured, not assumed. In the 1x1 probe:

    one  sa=0 da=0  -> (200,100,50,0)   // source verbatim, not destination
    one  sa=0 da=39 -> (40,80,120,39)   // destination untouched
    one  sa=1 da=0  -> (200,100,50,1)   // source verbatim

So `da == 0` is tested first; a zero source alpha only leaves the destination
alone when the destination is non-empty.

The parity-relevant asymmetry: **color weights are 256-scaled** (`w`, `256-w`,
`>> 8`) while the **alpha divisor is 255-scaled** (`num // 255`). Plain
straight-alpha normalization — float or exact rational — is not the original
behavior; it reproduces the host's two-byte error.

## Host formula (current source)

`Scripts/RubyClasses/Bitmap.cs` `AlphaOver`:

    invA  = 1.0f - source.A
    alpha = source.A + dest.A * invA
    rgb   = (source.RGB*source.A + dest.RGB*dest.A*invA) / alpha
    -> Godot Image.SetPixel truncates each channel to 8 bits

`BlendImage` applies it once per blit, so the Rgba8 image quantizes after every
corner. That per-step quantization plus the 255-scale normalization is the whole
difference.

## Measured evidence

All captures are original-runtime output from isolated RGSS300 fixture projects.
No host build was needed. Harness: `.omo/compatibility-run-tmp/d05-cache-diagnosis-redgreen.py`;
output: `.omo/evidence/d05-cache-diagnosis/red-green.txt`.

| artifact | rows | content |
|----------|------|---------|
| `d05-cache-diagnosis-original/d05_cache_diagnosis.tsv` | 36 stage + 100 one-step + 16 two-step + 4 opacity | cache dumped after each of the four blits |
| `d05-cache-diagnosis-blt4-original/d05_blt4_grid.tsv` | 14,080 | 4x4 blt transfer function: 11 dst alphas x 256 src alphas x 5 color patterns |
| `d05-cache-diagnosis-transfer-original/d05_transfer_grid.tsv` | 12,800 | 1x1 blt transfer function (cross-check) |

Model comparison:

    RED   host float32 model vs original cache      : 2/9 pixels differ  [(1,1), (1,2)]
    GREEN integer model vs original cache           : 0/9 pixels differ
    host float32 model vs host TSV                  : 0/9 differ
    RED   host float32 model vs original 4x4 grid   : 982/14080 differ
    GREEN integer model vs original 4x4 grid        : 0/14080 differ
    RED   host float32 model vs 36 staged values    : 15/36 differ
    GREEN integer model vs 36 staged values         : 0/36 differ

Host-model divergence across the four accumulation stages (reproduced by the
harness from the alpha-bearing stage dump):

    stage 0: 1/9    stage 1: 6/9    stage 2: 6/9    stage 3: 2/9
    by channel: blue 7, green 6, red 2
    by column:  x=0 4, x=1 5, x=2 6

The error is present from the first overlapping blit and is progressively
absorbed; only two channel values survive to the final cache. That is why the
symptom is two bytes and not fifteen.

The red model reproduces the host TSV exactly, which proves it is a faithful
transcription of the shipping code and that the divergence is arithmetic, not a
reading error. The green model is exact on every measured cache value.

### Measured 256-scale weights

The 4x4 grid isolates each term. `src_only` is `src=(255,0,0,sa)` over
`dst=(0,0,0,da)`; `dst_only` is the mirror. Recovering the implied integer
weight from the output byte gives weights that always sum to exactly 256:

| da | sa | W_src | W_dst | sum | exact 256*sa/A | exact 256*dst_term/A |
|----|----|-------|-------|-----|----------------|----------------------|
| 1  | 1  | 128   | 128   | 256 | 128.25         | 127.75               |
| 1  | 2  | 171   | 85    | 256 | 171.11         | 84.89                |
| 32 | 32 | 137   | 119   | 256 | 136.57         | 119.43               |
| 64 | 64 | 146   | 110   | 256 | 146.37         | 109.63               |
| 128| 128| 171   | 85    | 256 | 170.89         | 85.11                |
| 254| 242| 243   | 13    | 256 | 243.00         | 13.00                |

A 255-scale model cannot produce a constant 256 sum; this is the direct
measurement of the asymmetry above.

Alpha is separately 255-scaled: `alpha_out = floor(A_exact * 255)` matched every
`src_only` row with 0 mismatches, including cases where the two scales disagree.

### Measured staged cache (36 values, original runtime)

    stage 0   (20,40,60,32)   (20,45,60,39)   (20,50,60,46)
              (20,40,65,32)   (32,45,65,39)   (32,50,65,46)
              (20,40,70,32)   (32,45,70,39)   (44,50,70,46)
    stage 1   (20,183,60,237) (20,188,60,243) (20,193,60,250)
              (31,183,65,237) (32,188,65,243) (20,193,65,250)
              (43,183,70,237) (32,188,70,243) (20,193,70,250)
    stage 2   (20,163,79,239) (21,165,83,244) (24,166,86,250)
              (29,163,84,239) (32,165,88,244) (22,166,91,250)
              (39,163,89,239) (30,165,93,244) (20,166,96,250)
    stage 3   (42,183,195,253)(31,188,198,254) (20,194,202,254)
              (31,183,200,253)(32,188,203,254) (20,194,207,254)
              (21,183,205,253)(20,188,208,254) (20,194,212,254)

Stage 3 is the final cache and matches `cursor_cache_reference.tsv` exactly.

### Why exactly those two pixels

Pixel (1,1), final step: source `(32,190,210,242)` over `(32,165,88,244)`.

    255-scale exact blue = 204.0356   -> floor 204   (host float32 also 204)
    256-scale exact blue = 203.8047   -> floor 203   (original)
    scale gap            = 0.2309 byte

    num = 255*242 + 244*13 = 64882
    a   = 64882 // 255     = 254
    w   = 65025*242 // 64882 + 1 = 243      (256-w = 13)
    blue = (210*243 + 88*13) >> 8 = 52174 >> 8 = 203

The 256-scale weight is 0.2309 byte lower than the 255-scale normalized weight.
The true value sits only 0.0356 above the boundary, so that 0.2309 is enough to
push it below. Pixel (1,2) is identical in structure: 255-scale 209.0356,
256-scale 208.8047, original 208, host 209.

Pixel (1,0) has the *same* final-step fraction (255-scale 199.0356) yet does not
diverge. Its host intermediate already differed one stage earlier — host stage 2
gives blue 82 where the original gives 83 — and that earlier -1 cancels the final
+1, landing both on 198. So the surviving error is not "the pixels with a small
fraction"; it is "the pixels where the per-step float error does not happen to
cancel". This is why the model comparison must be run stage by stage (15/36)
rather than only on the final cache (2/9).

### Two-step and opacity spot checks

    two2 sa=39 da=242 -> (12,218,89,243)
      num = 255*242 + 39*13 = 62217, a = 243, w = 65025*242//62217 + 1 = 253
      (10*253 + 200*3)>>8 = 12 ; (220*253 + 100*3)>>8 = 218 ; (90*253 + 50*3)>>8 = 89

    opacity sa=242 op=128 -> (200,100,50,121)
      floor(242*128/255) = 121, then source verbatim onto an empty destination

Both match, so the formula also covers chained blits and the opacity parameter.

## Smallest proposed fix

Replace the float path in `BlendImage` / `StretchBlendImage` with the proven
integer formula on 8-bit channels:

    private static (int R, int G, int B, int A) AlphaOverBytes(
        int sr, int sg, int sb, int sa, int dr, int dg, int db, int da)
    {
        if (da == 0) return (sr, sg, sb, sa);
        if (sa == 0) return (dr, dg, db, da);
        var num = 255 * sa + da * (255 - sa);
        var a = num / 255;
        if (num == 0 || a == 0) return (0, 0, 0, 0);
        var w = 65025 * sa / num + 1;
        return (
            (sr * w + dr * (256 - w)) >> 8,
            (sg * w + dg * (256 - w)) >> 8,
            (sb * w + db * (256 - w)) >> 8,
            Math.Min(255, a));
    }

and have `BlendImage` read/write bytes (or `Color8`) instead of float `Color`,
so no intermediate quantization occurs between blits. One helper plus two call
sites; no coordinate special cases, no tolerance. `StretchBlendImage` inherits
it and must be re-verified against the stretch fixtures. `BlendTextPixel` and
`BlitGlyph` are separate float composites and out of scope.

## Window composite: measured scope and open question

Current host captures vs originals:

| capture | differing rows |
|---------|----------------|
| `window_cursor_alpha_reference.tsv` (black bg) | 2/3529, both at 3x3 |
| `window_cursor_alpha_white_reference.tsv` (white bg) | 5/3529, all at 3x3 |

Feeding the **proven cache** through the shader's current
`(c*(a+1) + bg*(256-a)) >> 8`:

- black background: 36/36 staged rows exact (the `bg` term vanishes, so this
  only confirms the cache and the `(a+1)` color coefficient);
- white background: 12/36 staged rows differ, **all in the x=2 column**;
- switching the background coefficient to `255-a` moves the failures to 24/72
  rows (stage 2 at x=0 and x=1 break instead).

So no single background coefficient reproduces both backgrounds, and the x=2
column is the only column where two corner pieces overlap (source columns 2 and
31, accumulated alphas 46 then 250). The black rows matching while the white rows
do not means the residual is in how the overlapping corner is combined with the
background, not in the cache values themselves.

**Exact remaining cause question:** for the 3x3 cursor's overlapping right-hand
column (x=2), does the original composite the two corner pieces against the
background sequentially — piece A over background, then piece B over that result
— rather than accumulating them into a cache first and compositing once? A
sequential composite would produce a different alpha/color pair than the
accumulated cache at that column, which is what the white-background rows imply,
while leaving the black-background rows unchanged because both pieces are then
composited against the same black.

This is independent of the cache fix and is not resolved here.

## Assumptions and limits

- Original captures under `.omo/compatibility-run-tmp/*-original` are treated as
  authoritative; only the `d05-cache-diagnosis-*` projects were generated here.
- The 4x4 grid is the same code path as the fixture's blits (both `Bitmap#blt`
  with a 4x4 source rect). The 1x1 grid is a cross-check only.
- No production file was modified. Nothing was built and no GUI capture was
  taken; all evidence is original-runtime TSV plus the Python harness.
- The proposed fix is a proposal. It has not been applied, compiled, or run
  against the host, so its green status is model-level, not build-level.

Lead follow-up: the proven integer weight formula is now applied only to
Bitmap.cs AlphaOver and its two blt/stretch callers, including integer opacity
alpha truncation and empty-destination source-byte preservation. C# diagnostics
are clean; build is active. Actual cache/bitmap regressions remain pending.
The cursor shader's separate screen composite is unchanged and unaccepted.

Actual host verification now passed: build exit 0, CURSOR_CACHE_PASS exit 0
and BITMAP_COMPOSITING_PASS exit 0. The two blue-channel differences are gone.
The nine-row original baseline is pinned in tests/fixtures/cursor_cache_original.tsv
and the headless runner is registered in the unified suite. Public API check
is active. No D05 final screen-parity acceptance is implied by this cache fix.

The cursor shader's overlapping-corner cache now uses the same proven integer
formula with integer arithmetic, replacing its float cache normalization.
Black/white original screen comparisons are running to observe the independent
final-composite residual. The background formula itself is unchanged.

The first shader run failed compilation because vec4(ivec3,int) requires explicit
float/vector conversion. The ordinary attack check was stopped because that
shared shader error invalidated its rendered surface. The conversion is now
fixed and one black-background cursor run is active before any other renderer
regression resumes. The earlier CPU cache/Bitmap/API passes remain settled.

Corrected GPU integer cache passed all 3529 black-background rows, exit 0.
White-background comparison now differs only at x2 in the 3x3 cursor: three
pixels, all RGB channels +1; other rows match. The previous two blue cache
differences are gone. This is the independent final-background composite gap;
no coordinate-specific correction is applied. Ordinary attack renderer check
is active on the now-valid shader.

Alpha byte round-trip hypothesis was tested by rounding the byte before
opacity. It did not change the three white-column differences; the hypothesis
was rejected and the trial reverted. Proven integer cache remains intact.
Ordinary attack subsequently passed BATTLE_TURN_PASS, exit 0. No final
background-composite fix is claimed.
