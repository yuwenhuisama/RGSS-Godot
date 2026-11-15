root=File.expand_path('..',__dir__)
events=[0,0xc0,0,0,0x90,60,100,0x8f,0,0x80,60,0,0,0xff,0x2f,0].pack('C*')
header='MThd'+[6].pack('N')+[0,1,480].pack('n*')
File.binwrite(File.join(root,'tests/fixtures/midi-reference.mid'),header+'MTrk'+[events.bytesize].pack('N')+events)
sysex=[0,0xf0,5,0x7e,0x7f,9,1,0xf7,0,0xc0,0,0,0x90,60,100,0x8f,0,0x80,60,0,0,0xff,0x2f,0].pack('C*')
File.binwrite(File.join(root,'tests/fixtures/midi-reference-sysex.mid'),header+'MTrk'+[sysex.bytesize].pack('N')+sysex)
timing='MThd'+[6].pack('N')+[0,1,0xe728].pack('n*')
File.binwrite(File.join(root,'tests/fixtures/midi-reference-smpte.mid'),timing+'MTrk'+[events.bytesize].pack('N')+events)
puts 'MIDI_FIXTURE_READY'
