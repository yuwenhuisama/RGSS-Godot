output = $rgss_compat_output || '.'
File.open(File.join(output, 'zlib_checksum_reference.tsv'), 'w') do |file|
  probes = [
    ['crc-combine', proc { Zlib.crc32_combine(1, 2, 5) }],
    ['adler-combine', proc { Zlib.adler32_combine(Zlib.adler32('Wiki'), Zlib.adler32('pedia'), 5) }],
    ['crc-combine-empty', proc { Zlib.crc32_combine(Zlib.crc32('1234'), Zlib.crc32(''), 0) }],
    ['adler-combine-empty', proc { Zlib.adler32_combine(Zlib.adler32('Wiki'), Zlib.adler32(''), 0) }],
    ['crc-table', proc { table = Zlib.crc_table; [table.size, table[0], table[1], table[255]].join(',') }],
    ['version-format', proc { Zlib.zlib_version =~ /^\d+\.\d+\.\d+$/ ? true : false }]
  ]
  probes.each do |name, probe|
    next if $zlib_checksum_cases && !$zlib_checksum_cases.include?(name)
    File.open(File.join(output, 'zlib_checksum_progress.txt'), 'w') { |progress| progress.puts(name) }
    begin
      file.puts [name, probe.call].join("\t")
    rescue StandardError => error
      file.puts [name, 'error', error.class].join("\t")
    end
    file.flush
  end
end
exit unless $zlib_checksum_host
