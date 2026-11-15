# Small cursor alpha residual

Current result: formal production shader passes the1890-row odd/even sweep
and both3529-row black/white cursor matrices at exit0. The three white3x3
residual pixels are gone under the measured paired/scalar-tail destination
weight. Process-local trial code was removed; the sweep owner is registered
in rendered regressions. Message-window regression is active. Earlier failed
models and experiments below are historical evidence.

The affected rendered/font regression completes TEST_SUITE_PASS:15, exit 0,
including the newly registered tail owner. Message baseline360 and actual
input scenarios also pass. Independent four-pair visual inspection is pending;
these checks close the measured cursor arithmetic defect only.

New model evidence: all72 dual-background staged rows match when paired
pixels use the current256-alpha destination weight and the unpaired final
pixel uses255-alpha. The existing model misses12 rows, all last column of
width3; exact/ceil-alpha alternatives miss33/47 rows. This suggests a vector
pair/scalar-tail blend distinction, not a column2 correction. Original widths
1..9 and heights1/3/8/9 on black/white backgrounds are running to test whether
the difference follows odd-width tails. No shader changed before this probe.

Original width/height sweep contains1890 rows. Shipping host differs105 rows:
white background only, one last-column pixel per row for widths1/3/5/7/9;
all even widths and all black backgrounds match. An in-process shader trial
uses the scalar destination weight only for an odd-width unpaired tail; its
1890-row replay is active without editing the shared production shader during
the ongoing event suite.

First in-process trial leaves all105 rows byte-identical to the shipping
output. The locally loaded Shader reference was dropped before native renderer
GD.Load, allowing weak resource-cache eviction/reload. Trial now retains a
strong Shader field and asserts replacement presence before render; replay
active. This is not evidence rejecting the arithmetic model until it runs.

Retained-resource trial passes CURSOR_TAIL_PASS exit0: all1890 original rows
match under the paired-pixel/scalar-tail rule. The105 red rows disappear;
even widths and black backgrounds remain exact. This is executable shader
evidence for the row-tail branch. Production shader deployment waits for the
currently running event suite so its inputs are not changed mid-run.

Current stored black-background alpha matrix matches all3529 original rows.
White-background matrix differs in exactly3 rows, all3x3 column2; host RGB
is one level above original at each of those pixels.

The current integer cache model produces first-row RGBA by column:
(42,183,195,253), (31,188,198,254), (20,194,202,254).
The paired background outputs constrain the last column's effective alpha
differently: original white-minus-black is1, host is2. This is an alpha/cache
quantization question, not justification for a coordinate special case.

Original staged corners for column2,row0:
black stage0=(3,9,11), stage1=(19,189,58), stage2=(23,162,84),
stage3=(19,193,201); white stage0=(211,217,219), stage1=(24,194,63),
stage2=(28,167,89), stage3=(20,194,202).
Stored evidence is in cursor-corner-stages-original. No shader was changed;
D05 remains open until one accumulation rule explains the complete matrices.

Exact dual-background integer inference under the current final formula
floor((RGB*(alpha+1)+background*(256-alpha))/256) gives unique first-row
cache candidates for column0=(42,183,195,253) and column1=(31,188,198,254).
Column2 has no integer RGBA candidate satisfying both original black and white
outputs. Stages0..2 do admit candidates; stage3 does not. Therefore merely
adjusting an integer cached alpha cannot explain the final residual under
this formula. The last accumulation or final blend representation needs an
independent model; no column-specific correction is justified.
