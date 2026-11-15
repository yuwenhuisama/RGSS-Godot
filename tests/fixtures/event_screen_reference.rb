output = $rgss_compat_output || '.'
saved = [$game_map, $game_message, $game_party, $game_variables, $data_system]
begin
  $data_system = RPG::System.new
  $data_system.variables = [nil] + Array.new(10, 'variable')
  $game_map = Game_Map.new
  $game_message = Game_Message.new
  $game_party = Game_Party.new
  $game_variables = Game_Variables.new
  $game_variables[1] = 40
  $game_variables[2] = 60
  cases = [
    ['fade-out', 221, []], ['fade-in', 222, []],
    ['tone-wait', 223, [Tone.new(80, -40, 20, 60), 4, true]],
    ['tone-nowait', 223, [Tone.new(-20, 50, 100, 0), 3, false]],
    ['flash-wait', 224, [Color.new(200, 80, 40, 160), 4, true]],
    ['shake', 225, [5, 6, 8]],
    ['picture-direct', 231, [1, 'Probe', 0, 0, 10, 20, 100, 80, 200, 0]],
    ['picture-variable', 231, [1, 'Probe', 1, 1, 1, 2, 120, 90, 180, 1]],
    ['picture-move-wait', 232, [1, '', 0, 0, 100, 80, 150, 120, 80, 2, 4, true]],
    ['picture-move-nowait', 232, [1, '', 1, 1, 1, 2, 100, 100, 255, 0, 3, false]],
    ['picture-rotate', 233, [1, 8]],
    ['picture-tone', 234, [1, Tone.new(10, 20, 30, 40), 3, true]],
    ['weather-rain', 236, [:rain, 6, 4, true]],
    ['weather-snow', 236, [:snow, 3, 3, false]],
    ['weather-clear', 236, [:none, 0, 2, true]],
    ['picture-erase', 235, [1]],
    ['flash-nowait', 224, [Color.new(40, 160, 220, 100), 3, false]],
    ['shake-zero-duration', 225, [3, 4, 0]],
    ['picture-tone-nowait', 234, [1, Tone.new(-10, 40, 80, 20), 3, false]],
    ['picture-zero-duration', 232, [1, '', 0, 0, 15, 25, 80, 60, 100, 0, 0, true]],
    ['tone-zero-duration', 223, [Tone.new(20, 30, 40, 50), 0, true]],
    ['weather-storm', 236, [:storm, 9, 3, true]]
  ]
  File.open(File.join(output, 'event_screen_reference.tsv'), 'w') do |file|
    cases.each do |name, code, parameters|
      interpreter = Game_Interpreter.new
      interpreter.setup([RPG::EventCommand.new(code, 0, parameters), RPG::EventCommand.new])
      frame = 0
      while interpreter.running? || frame < 8
        raise "screen command hung: #{name}" if frame >= 100
        interpreter.update
        screen = $game_map.screen
        picture = screen.pictures[1]
        values = [name, frame, interpreter.running?, screen.brightness,
          screen.tone.red, screen.tone.green, screen.tone.blue, screen.tone.gray,
          screen.flash_color.alpha, screen.shake, screen.weather_type, screen.weather_power,
          picture.name, picture.origin, picture.x, picture.y, picture.zoom_x,
          picture.zoom_y, picture.opacity, picture.blend_type, picture.angle,
          picture.tone.red, picture.tone.green, picture.tone.blue, picture.tone.gray]
        file.puts(values.map { |value| value.is_a?(Numeric) ? sprintf('%.9f', value) : value.to_s }.join("\t"))
        file.flush
        screen.update
        frame += 1
      end
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_screen_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_message, $game_party, $game_variables, $data_system = saved
end
exit unless $rgss_compat_output
