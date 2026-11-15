File.open('sprite_trace_ready.txt','w') {|file|file.write('READY')}
600.times {Graphics.update}
eval(File.read(TestPaths.fixture('sprite_rotated_effect_reference.rb')))
