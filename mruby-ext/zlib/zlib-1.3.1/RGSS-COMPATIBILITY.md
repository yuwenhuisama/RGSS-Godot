Local RGSS300 compatibility modification

inflate.c retains wrapper and checksum validation after inflateSync, matching
the measured original runtime and the upstream zlib 1.2.5 recovery policy.
The unmodified zlib 1.3.1 path disables checks or treats an uninitialized
wrapper as raw; the shared FULL_FLUSH recovery fixture therefore succeeded
where RGSS300 raises Zlib::DataError.

Evidence: tests/fixtures/zlib_stream_reference.rb, inflate-sync-recovery;
tests/fixtures/zlib_stream_original.tsv. Original and corrected host produce
true,,Zlib::DataError. This source is modified and is not pristine upstream.

Upstream comparison: https://raw.githubusercontent.com/madler/zlib/v1.2.5/inflate.c
