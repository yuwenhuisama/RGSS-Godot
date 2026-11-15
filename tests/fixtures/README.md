# Fixture provenance

These fixtures are test inputs and independent RGSS300 measurements. They
are not a bundled game or licensed RTP. Corresponding topic reports under
`docs/compatibility` describe capture commands, hashes and measured limits.

- `*_reference.rb` scripts are isolated original/host probes. Some original
  branches keep the workstation paths used for the recorded captures. Host
  runners provide their fixture paths where required; the full RPG database
  and game-flow owners need separately installed local game/RTP data.
- `*_original.tsv`, RGSS300 font/text `.rgba` and related tables are preserved
  original-runtime outputs. Keep their exact bytes; do not regenerate them
  merely to make a host test pass. `rpg_database_original_hashes.tsv` describes
  15 canonical local game database files rather than distributing those files.
- `save_interchange_original.rvdata2` is a generated probe save for the
  documented stock-game interchange owner, not a user's personal save.
- `audio/tone.*`, tagged loop audio, MIDI and Theora fixtures are synthetic
  signal/motion inputs. Their generation and original comparisons are in the
  audio, MIDI and movie reports and `tools/create_midi_fixture.rb`.
- `bitmap-file-reference.png` and pixel fixtures exercise runtime loading and
  rendering; they are test images, not production game assets.
- `third_party/Ace_Core_Engine.rb` is the unmodified Yanfly Ace Core Engine
  v1.09 (2012-02-19), sourced through the author's official page and linked
  repository: https://yanflychannel.wordpress.com/rmvxa/core-scripts/ace-core-engine/
  and https://github.com/Archeia/YEARepo/blob/master/Core/Ace_Core_Engine.rb.
  Original SHA256 is
  `71b90cbe19d18089a9829a80b1289c8a36b68bd30acc7a6babdf0ca660fdd6e2`.
  Author terms remain in the source and linked official page; no additional
  license is asserted here. See `third-party-script-verification.md` for the
  versioned test scope.
