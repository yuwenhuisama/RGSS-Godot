require 'zlib'
root=File.expand_path('../..', __dir__)
script=File.read(File.join(root,'RGSS-Godot/tests/fixtures/movie_observe_reference.rb'))
path=File.join(root,'RGSS-Godot/.omo/compatibility-run-tmp/b07-wide-original/Data/Scripts.rvdata2')
File.binwrite(path,Marshal.dump([[1,'MovieObserve',Zlib::Deflate.deflate(script)]]))
puts 'MOVIE_OBSERVE_READY'
