output = $rgss_compat_output || '.'
File.open(File.join(output, 'zlib_family_reference.tsv'), 'w') do |file|
  file.puts ['module-methods', Zlib.singleton_methods(false).map { |name| name.to_s }.sort.join(',')].join("\t")
  file.puts ['constants', Zlib.constants.map { |name| name.to_s }.sort.join(',')].join("\t")
  %w[GzipFile GzipReader GzipWriter].each do |name|
    if Zlib.const_defined?(name)
      klass = Zlib.const_get(name)
      file.puts [name, klass.instance_methods(false).map { |method| method.to_s }.sort.join(',')].join("\t")
    else
      file.puts [name, 'missing'].join("\t")
    end
  end
end
exit unless $zlib_family_host
