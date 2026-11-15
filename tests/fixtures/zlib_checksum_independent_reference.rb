$zlib_checksum_host = true
$zlib_checksum_cases = %w[adler-combine crc-combine-empty adler-combine-empty crc-table version-format]
eval(File.read(TestPaths.fixture('zlib_checksum_reference.rb')))
exit
