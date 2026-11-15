# Marshal IO/depth contract

Baseline: installed Chinese RGSS300, 2026-11-13. Shared
`tests/fixtures/marshal_io_reference.rb` records seven contracts: IO return
identity, IO roundtrip, bytes equal to string dump, explicit nil IO TypeError,
positional depth, third-argument depth with IO, and depth-limit ArgumentError.
Completed original exit0, normalized SHA256
`188be7f92851f02f5be75af296e1d39c321eab353c8662d3a9f88bef26ebcfa0`.

The cross-map event probe first exposed missing optional-argument registration:
native dump parser already handled o|oi but registered only MRB_ARGS_REQ(1).
Registration corrected to MRB_ARGS_ARG(1,2), allowing real save_data(obj,file).
This seven-contract probe then failed only explicitnil: originalTypeError,
Godotaccepted. Native now rejects explicitnil IO before choosing string writer;
build and the same regression are pending. No dump/save fallback was added.

Nativebuildexit0, plugin deployed after preserving priorbinary, managedbuildexit0;
MARSHAL_IO_PASSexit0 for the same7original contracts. Runner registered in
the headless aggregator. Cross-map save regression running after typecheck change.

Cross-map90frame EVENT_TRANSFER_PASSexit0 after latestplugin. Full37runner
suite nowrunning. CI's hardcodedheadless count9 would reject new10member suite,
so its marker check nowaccepts the exact TEST_SUITE_PASS:number line while
retaining childexit and expectedmarker checks. YAMLparse and markerpositive/
negative probes passed locally; no macOS/Linux workflow execution is claimed.

Runner: `godot --headless --path . -s tests/test_marshal_io.gd`.
Original preparation: tools/prepare_original_fixture.rb with this shared fixture
in a new owned destination, then Game.exe from that directory. IO artifacts
are written under its output directory; source game untouched.

F04 remains open: reference graphs, cycles, user hooks, encoding and malformed
data require further measured cases. These seven contracts do not prove full
Marshal compatibility or original/Godot savegame interoperability.
