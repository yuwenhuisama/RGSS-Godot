Graphics.update
File.open('sprite_trace_ready.txt','w') {|file|file.write('READY')}
1200.times {Graphics.update}
eval(File.read(TestPaths.fixture('sprite_sampling_reference.rb')))
