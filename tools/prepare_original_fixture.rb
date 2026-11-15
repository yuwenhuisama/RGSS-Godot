require 'fileutils'
require 'zlib'

# Creates an isolated RGSS3 project; never writes into the source game.
source, destination, script = ARGV
abort 'Usage: ruby tools/prepare_original_fixture.rb SOURCE_GAME DESTINATION SCRIPT' unless source && destination && script
abort 'Destination already exists' if File.exist?(destination)
FileUtils.mkdir_p(File.join(destination, 'Data'))
FileUtils.mkdir_p(File.join(destination, 'System'))
FileUtils.cp(File.join(source, 'Game.exe'), destination)
ini = File.read(File.join(source, 'Game.ini'))
library = ini.lines.find { |line| line.start_with?('Library=') }.split('=', 2).last.strip
FileUtils.cp(File.join(source, library.tr('\\', '/')), File.join(destination, library.tr('\\', '/')))
File.write(File.join(destination, 'Game.ini'), "[Game]\nRTP=\nLibrary=#{library}\nScripts=Data\\Scripts.rvdata2\nTitle=RGSS Compatibility Fixture\n")
payload = [[1, 'Compatibility', Zlib::Deflate.deflate(File.read(script))]]
if ARGV[3] == '--tile-render'
  payload = [[1, 'Compatibility', Zlib::Deflate.deflate("$tilemap_probe_render=true\n" + File.read(script))]]
end
if ARGV.include?('--tile-tables')
  payload = [[1, 'Compatibility', Zlib::Deflate.deflate("$tilemap_probe_tables=true\n" + File.read(script))]]
end
if ARGV.include?('--tile-render') && ARGV.include?('--tile-tables')
  payload = [[1, 'Compatibility', Zlib::Deflate.deflate("$tilemap_probe_render=true\n$tilemap_probe_tables=true\n" + File.read(script))]]
end
if ARGV[3] == '--tile-animation'
  payload = [[1, 'Compatibility', Zlib::Deflate.deflate("$tilemap_probe_animation=true\n" + File.read(script))]]
end
if ARGV[3] == '--tile-origin'
  payload = [[1, 'Compatibility', Zlib::Deflate.deflate("$tilemap_probe_origin=true\n" + File.read(script))]]
end
if ARGV[3] == '--record-transition'
  payload = [[1, 'Compatibility', Zlib::Deflate.deflate("$record_transition_video=true\n" + File.read(script))]]
end
if ARGV[3] == '--stock-scripts'
  stock = Marshal.load(File.binread(File.join(source, 'Data', 'Scripts.rvdata2')))
  payload = stock.reject { |entry| entry[1] == 'Main' } + payload
end
File.binwrite(File.join(destination, 'Data', 'Scripts.rvdata2'), Marshal.dump(payload))
puts "ORIGINAL_FIXTURE_READY:#{File.expand_path(destination)}"
