# Short-line font placement

Final measured result: `FONT_SHORT_LAYOUT_PASS`, exit 0, for all 90 original
cases. Managed build and the existing 35 font-style pixel comparisons passed.
The runner is registered in the unified Windows-font suite. Default window
render/input regression is running after this change; D05 still requires its
remaining window composition differences to be explained.

The D05 stock-window captures revealed one-pixel vertical displacement and
right-aligned text advance differences. A shared 90-case fixture now measures
Arial 24, outline on/off, line heights 8/23/24/25/40, three alignments and
three text runs (`A`, `123`, `: 1`). It records public text metrics and the
bounding box of pixels with alpha greater than 32.

Original RGSS300 ran the isolated fixture and exited 0. Normalized baseline
SHA256: `db13e123dabad6326453693c77c21cbacb63a95706c09f3ab441f8ae8bb0deb0`.
The regression pins that independent hash and does not require the temporary
original project to remain installed.

The initial Godot comparison failed. Accounting for the two-pixel outline
extent when centering vertically and aligning horizontally fixed ordinary
outlined line heights for multi-character runs. Managed build exited 0 and
the existing 35 font-style pixel comparisons still passed. The 90-case probe
remains red on 23 cases: non-outline A center/right alignment, outline A right
alignment, and all outlined 8-pixel-high rows. Actual glyph extent and source
clipping order remain under investigation; the goal is not closed.

Changing the rasterizer's layout measurement from glyph advances to GDI text
extent did not change these failures and was restored to the original advance
measurement. The remaining alignment needs a measured rendered extent, not a
substitution of public text_size. The 8-pixel case also demonstrates that
outlining an already clipped glyph differs from clipping its finished outline;
the current renderer does the latter. No special-case offset was added.

Runner: `godot --headless --path . -s tests/test_font_short_layout.gd`.
Ruby fixture syntax passed. C# symbol lookup failed in the local LSP tool;
Ruby LSP is unavailable. Build and executable contracts provide current
diagnostics; no language-server installation is claimed.

Next measured hypothesis: the layout width must include the rightmost GDI
glyph ink extent when it exceeds advance width. The rasterizer now retains
that extent for draw placement without changing public text_size. Shadow and
outline passes now limit their source rows to the requested line height;
foreground remains clipped at the destination. Managed build exited 0.
The same 90-case probe and existing 35 style comparisons are running; this
entry is a hypothesis and build result, not a passing layout receipt.

That run preserved all 35 style samples and reduced the 90-case failures from
23 to 11. The remaining short-row differences included untrimmed foreground
glyph rows, and outlined center alignment rounds the half-pixel position upward.
The foreground pass now shares the source-height limit and outline center
placement uses that rounding. Build and the same probe are pending.

The next build and style regression passed; all center/right alignment cases
now agree. Six cases remain: outline-enabled height 8 for `123` and `: 1`
in all three alignments. Their left edge is two pixels too far left. The last
source row contributes that edge when expanded; limiting outlined source
height by its outline margin is now being tested. No ordinary-height behavior
is claimed changed by that boundary.
