raise 'export defined mismatch' unless defined?(Object) == 'constant'
payload = [2 ** 100, 'linux-export', {:value => 42}]
raise 'export marshal mismatch' unless Marshal.load(Marshal.dump(payload)) == payload
path = File.join(Unity.rmva_project_path, 'linux-export.gz')
Zlib::GzipWriter.open(path) { |writer| writer.write('linux exported gzip') }
Zlib::GzipReader.open(path) { |reader| raise 'export gzip mismatch' unless reader.read == 'linux exported gzip' }
puts 'LINUX_EXPORTED_RUBY_PASS'
