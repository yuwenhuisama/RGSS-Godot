Graphics.update
File.open('sprite_trace_ready.txt','w') {|file|file.write('READY')}
1200.times {Graphics.update}
eval(File.read('E:/Projects/RGSS-Godot/tests/fixtures/sprite_sampling_reference.rb'))
