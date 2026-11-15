output = $rgss_compat_output || '.'
saved = [$game_map, $game_message, $game_variables, $data_system]
begin
  $data_system = RPG::System.new
  $data_system.variables = [nil] + Array.new(10, 'variable')
  $game_map = Game_Map.new
  $game_message = Game_Message.new
  $game_variables = Game_Variables.new
  cases = [
    ['text', [[101, 0, ['Face', 2, 1, 0]], [401, 0, ['First']], [401, 0, ['Second']]], nil],
    ['choice-first', [[102, 0, [['Red', 'Blue'], 5]], [402, 0, [0, 'Red']],
      [122, 1, [1, 1, 0, 0, 11]], [402, 0, [1, 'Blue']],
      [122, 1, [1, 1, 0, 0, 22]], [403, 0, []], [122, 1, [1, 1, 0, 0, 33]], [404, 0, []]], 0],
    ['choice-second', [[102, 0, [['Red', 'Blue'], 5]], [402, 0, [0, 'Red']],
      [122, 1, [1, 1, 0, 0, 11]], [402, 0, [1, 'Blue']],
      [122, 1, [1, 1, 0, 0, 22]], [403, 0, []], [122, 1, [1, 1, 0, 0, 33]], [404, 0, []]], 1],
    ['choice-cancel', [[102, 0, [['Red', 'Blue'], 5]], [402, 0, [0, 'Red']],
      [122, 1, [1, 1, 0, 0, 11]], [402, 0, [1, 'Blue']],
      [122, 1, [1, 1, 0, 0, 22]], [403, 0, []], [122, 1, [1, 1, 0, 0, 33]], [404, 0, []]], 4],
    ['number', [[103, 0, [2, 4]]], nil],
    ['item', [[104, 0, [3]]], nil],
    ['scroll', [[105, 0, [3, true]], [405, 0, ['Scroll one']], [405, 0, ['Scroll two']]], nil],
    ['text-choice', [[101, 0, ['', 0, 0, 2]], [401, 0, ['Pick']],
      [102, 0, [['Yes', 'No'], 0]], [402, 0, [0, 'Yes']],
      [122, 1, [1, 1, 0, 0, 44]], [404, 0, []]], 0],
    ['text-number', [[101, 0, ['', 0, 2, 1]], [401, 0, ['Number']], [103, 0, [2, 2]]], nil],
    ['text-item', [[101, 0, ['', 0, 1, 2]], [401, 0, ['Item']], [104, 0, [3]]], nil],
    ['busy-text', [[101, 0, ['', 0, 0, 2]], [401, 0, ['After existing message']]], nil],
    ['busy-choice', [[102, 0, [['Continue', 'Stop'], 0]]], 1],
    ['scroll-fast', [[105, 0, [1, false]], [405, 0, ['Fast scroll']]], nil]
  ]
  File.open(File.join(output, 'event_message_reference.tsv'), 'w') do |file|
    cases.each do |name, commands, selection|
      $game_message.clear
      busy = name.start_with?('busy-')
      $game_message.add('Existing message') if busy
      list = commands.map { |code, indent, parameters| RPG::EventCommand.new(code, indent, parameters) }
      list << RPG::EventCommand.new
      interpreter = Game_Interpreter.new
      interpreter.setup(list)
      (busy ? 8 : 5).times do |frame|
        interpreter.update
        message = $game_message
        file.puts([name, frame, interpreter.running?, message.busy?, message.all_text,
          message.face_name, message.face_index, message.background, message.position,
          message.choices.join('|'), message.choice_cancel_type,
          message.num_input_variable_id, message.num_input_digits_max,
          message.item_choice_variable_id, message.scroll_mode, message.scroll_speed,
          message.scroll_no_fast, $game_variables[1]].map { |value| value.to_s.gsub("\n", '\\n') }.join("\t"))
        file.flush
        if frame == 2 || (busy && frame == 5)
          # Acknowledge the public message boundary; visible UI/input is D05.
          message.choice_proc.call(selection) if selection && (!busy || frame == 5)
          message.clear
        end
      end
      raise "message command did not finish: #{name}" if interpreter.running?
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_message_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_message, $game_variables, $data_system = saved
end
exit unless $rgss_compat_output
