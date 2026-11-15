$zlib_checksum_host = true
$zlib_checksum_cases = %w[crc-combine-empty adler-combine-empty]
eval(File.read(TestPaths.fixture('zlib_checksum_reference.rb')))
exit
