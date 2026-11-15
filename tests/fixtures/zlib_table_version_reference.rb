$zlib_checksum_host = true
$zlib_checksum_cases = %w[crc-table version-format]
eval(File.read(TestPaths.fixture('zlib_checksum_reference.rb')))
exit
