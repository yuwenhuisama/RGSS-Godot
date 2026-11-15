$zlib_checksum_host = true
$zlib_checksum_cases = %w[crc-combine-empty adler-combine-empty]
eval(File.read('E:/Projects/RGSS-Godot/tests/fixtures/zlib_checksum_reference.rb'))
exit
