# Original-runtime oracle: physical Windows input API, stock Input.update.
$d05_host = true
eval(File.read(TestPaths.fixture('message_window_reference.rb')))
module Cache
  class << self
    alias d05_input_load_bitmap load_bitmap
    def load_bitmap(folder, filename, hue = 0)
      d05_input_load_bitmap(TestPaths.rtp(folder), filename, hue)
    end
  end
end
output = $rgss_compat_output || '.'
key_event = Win32API.new('user32', 'keybd_event', 'iiii', 'v')
foreground = Win32API.new('user32', 'GetForegroundWindow', '', 'i')
window_pid = Win32API.new('user32', 'GetWindowThreadProcessId', 'ip', 'i')
process_pid = Win32API.new('kernel32', 'GetCurrentProcessId', '', 'i').call
advance = proc { |count| count.times { D05Message.step; Graphics.update } }
tap = proc do |key|
  pid = [0].pack('L')
  window_pid.call(foreground.call, pid)
  raise "Original input window lost foreground: expected PID #{process_pid}, actual PID #{pid.unpack('L')[0]}, handle #{foreground.call}" unless pid.unpack('L')[0] == process_pid
  begin
    key_event.call(key, 0, 0, 0)
    advance.call(2)
  ensure
    key_event.call(key, 0, 2, 0)
  end
  advance.call(2)
end
begin
  D05Message.prepare(output)
  # Launcher activates the window while these real frames initialize it.
  120.times { Graphics.update }
  File.open(File.join(output, 'message_input_ready.txt'), 'w') { |file| file.puts(process_pid) }
  600.times do
    break if File.exist?(File.join(output, 'message_input_activated.txt'))
    Graphics.update
  end
  raise 'Original ready-window activation did not arrive' unless File.exist?(File.join(output, 'message_input_activated.txt'))
  File.open(File.join(output, 'message_original_input.tsv'), 'w') do |file|
    %w[choice choice-cancel number item item-cancel text].each do |name|
      D05Message.start(name)
      advance.call(20)
      D05Message.blocked
      case name
      when 'choice'
        tap.call(0x28)
        D05Message.check(D05Message.instance_variable_get(:@choice).index == 1, 'choice cursor')
        tap.call(0x0d)
      when 'choice-cancel', 'item-cancel'
        tap.call(0x1b)
      when 'number'
        number = D05Message.instance_variable_get(:@number)
        D05Message.check(number.instance_variable_get(:@number) == 999, 'digits clamp')
        [0x26, 0x27, 0x28, 0x25, 0x25].each { |key| tap.call(key) }
        D05Message.check(number.instance_variable_get(:@number) == 89 && number.instance_variable_get(:@index) == 2, 'digit arithmetic and wrap')
        tap.call(0x1b)
        D05Message.blocked
        D05Message.check($game_variables[2] == 9876, 'cancel ignored')
        tap.call(0x0d)
      when 'item'
        tap.call(0x27)
        D05Message.check(D05Message.instance_variable_get(:@item).item.id == 2, 'item navigation')
        tap.call(0x0d)
      when 'text'
        D05Message.check(D05Message.instance_variable_get(:@message).pause, 'page pause')
        tap.call(0x0d)
        advance.call(12)
        D05Message.blocked
        D05Message.check(D05Message.instance_variable_get(:@message).pause, 'escape pause')
        tap.call(0x1b)
      end
      advance.call(36)
      D05Message.completed
      result = case name
      when 'choice' then $game_variables[1] == 22
      when 'choice-cancel' then $game_variables[1] == 33
      when 'number' then $game_variables[2] == 89
      when 'item' then $game_variables[3] == 2
      when 'item-cancel' then $game_variables[3] == 0
      when 'text' then $game_variables[9] == 77
      end
      D05Message.check(result, name + ' accepted result')
      file.puts [name, 'PASS'].join("\t")
      file.flush
      D05Message.stop
    end
  end
  D05Message.close
  File.open(File.join(output, 'message_original_input_complete.txt'), 'w') { |file| file.puts('D05_ORIGINAL_INPUT_PASS:6') }
rescue Exception => error
  File.open(File.join(output, 'message_original_input_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
end
exit
