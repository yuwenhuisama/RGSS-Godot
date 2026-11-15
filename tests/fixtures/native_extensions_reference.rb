output=$rgss_compat_output || '.'
File.open(File.join(output,'zlib_error_hierarchy.tsv'),'w') {|file|file.puts [Zlib::BufError.ancestors.join(','),Zlib::BufError < StandardError].join("\t")} if $native_extensions_host
File.open(File.join(output,'file_stat_capabilities.tsv'),'w') {|file|file.puts [File.respond_to?(:directory?),File.respond_to?(:symlink?),File.respond_to?(:stat)].join("\t")}
glob_root=File.join(output,'glob-probe')
Dir.mkdir(glob_root) unless File.directory?(glob_root)
Dir.mkdir(File.join(glob_root,'nested')) unless File.directory?(File.join(glob_root,'nested'))
['a.txt','b.rb','.hidden.txt','nested/c.txt'].each do |name|
  File.open(File.join(glob_root,name),'w') {|file|file.write('fixture')}
end
File.open(File.join(output,'native_extensions_reference.tsv'),'w') do |file|
  probes=[
    ['zlib-roundtrip',proc { Zlib::Inflate.inflate(Zlib::Deflate.deflate('native payload')) }],
    ['zlib-crc32',proc { Zlib.crc32('123456789') }],
    ['zlib-adler32',proc { Zlib.adler32('Wikipedia') }],
    ['zlib-crc32-seed',proc { Zlib.crc32('56789',Zlib.crc32('1234')) }],
    ['zlib-adler32-seed',proc { Zlib.adler32('pedia',Zlib.adler32('Wiki')) }],
    ['zlib-empty',proc { Zlib::Inflate.inflate(Zlib::Deflate.deflate('')).bytesize }],
    ['zlib-level0',proc { Zlib::Deflate.deflate('native payload',0).unpack('H*')[0] }],
    ['zlib-level9',proc { Zlib::Deflate.deflate('native payload',9).unpack('H*')[0] }],
    ['zlib-truncated',proc { compressed=Zlib::Deflate.deflate('native payload'); Zlib::Inflate.inflate(compressed[0,compressed.bytesize-3]) }],
    ['zlib-corrupt',proc { Zlib::Inflate.inflate('not compressed') }],
    ['zlib-invalid-level',proc { Zlib::Deflate.deflate('native payload',10) }],
    ['regexp-lookbehind',proc { /(?<=a)b/.match('abc')[0] }],
    ['regexp-captures',proc { /(a)(b)/.match('ab').captures.join(',') }],
    ['regexp-backref',proc { 'ab12'.gsub(/([a-z]+)([0-9]+)/,'\2-\1') }],
    ['regexp-scan',proc { 'a1b2'.scan(/([a-z])([0-9])/).map {|pair|pair.join(':')}.join(',') }],
    ['regexp-position',proc { /b/.match('abb',2).begin(0) }],
    ['regexp-ignorecase',proc { /ab/i.match('AB')[0] }],
    ['glob-star',proc { Dir.glob(File.join(glob_root,'*')).map {|path|path.sub(glob_root+'/','')}.sort.join(',') }],
    ['glob-recursive',proc { Dir.glob(File.join(glob_root,'**/*.txt')).map {|path|path.sub(glob_root+'/','')}.sort.join(',') }],
    ['glob-brace',proc { Dir.glob(File.join(glob_root,'*.{txt,rb}')).map {|path|path.sub(glob_root+'/','')}.sort.join(',') }],
    ['glob-dotmatch',proc { Dir.glob(File.join(glob_root,'*.txt'),File::FNM_DOTMATCH).map {|path|path.sub(glob_root+'/','')}.sort.join(',') }],
    ['symlink-file',proc { File.symlink?(File.join(glob_root,'a.txt')) }],
    ['symlink-missing',proc { File.symlink?(File.join(glob_root,'missing.txt')) }],
    ['glob-start-recursive',proc { Dir.chdir(glob_root) { Dir.glob('**/*.txt').sort.join(',') } }]
  ]
  if File.directory?(File.join(output,'junction-probe'))
    probes << ['symlink-junction',proc { File.symlink?(File.join(output,'junction-probe')) }]
    probes << ['glob-junction',proc { Dir.glob(File.join(output,'junction-probe/**/*.txt')).map {|path|path.sub(output+'/','')}.sort.join(',') }]
  end
  probes.each do |name,probe|
    # Each row is flushed so native failures retain their last completed case.
    begin
      file.puts [name,probe.call.to_s].join("\t")
    rescue StandardError => error
      file.puts [name,'error',error.class].join("\t")
      File.open(File.join(output,'native_extensions_errors.txt'),'a') {|trace|trace.puts [name,error.message,*error.backtrace].join("\n")}
    end
    file.flush
  end
end
exit unless $native_extensions_host
