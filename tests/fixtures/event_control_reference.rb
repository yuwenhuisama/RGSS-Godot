output = $rgss_compat_output || '.'
saved = [$game_map, $game_message, $game_switches, $game_variables,
  $game_self_switches, $game_timer, $data_system, $data_common_events]
begin
  $data_system = RPG::System.new
  $data_system.switches = [nil] + Array.new(30, 'switch')
  $data_system.variables = [nil] + Array.new(30, 'variable')
  $game_map = Game_Map.new
  $game_map.instance_variable_set(:@map_id, 7)
  $game_message = Game_Message.new
  $game_switches = Game_Switches.new
  $game_variables = Game_Variables.new
  $game_self_switches = Game_SelfSwitches.new
  $game_timer = Game_Timer.new
  common = RPG::CommonEvent.new
  common.list = [RPG::EventCommand.new(122, 0, [8, 8, 1, 0, 5]), RPG::EventCommand.new]
  $data_common_events = [nil, common]
  cases = {
    'switch-range' => [[121, 0, [1, 3, 0]], [121, 0, [2, 2, 1]]],
    'variable-arithmetic' => [[122, 0, [1, 3, 0, 0, 20]], [122, 0, [1, 1, 1, 0, 7]],
      [122, 0, [2, 2, 2, 0, 4]], [122, 0, [3, 3, 3, 0, 3]],
      [122, 0, [1, 1, 4, 0, 4]], [122, 0, [2, 2, 5, 0, 7]],
      [122, 0, [4, 4, 0, 1, 1]], [122, 0, [5, 5, 0, 4, '6 * 7']]],
    'switch-branch' => [[111, 0, [0, 1, 0]], [122, 1, [6, 6, 0, 0, 11]],
      [411, 0, []], [122, 1, [6, 6, 0, 0, 22]], [412, 0, []]],
    'variable-branch' => [[111, 0, [1, 1, 0, 6, 0]], [122, 1, [7, 7, 0, 0, 33]],
      [411, 0, []], [122, 1, [7, 7, 0, 0, 44]], [412, 0, []]],
    'self-switch' => [[123, 0, ['A', 0]], [111, 0, [2, 'A', 0]],
      [122, 1, [9, 9, 0, 0, 55]], [412, 0, []]],
    'loop-break' => [[122, 0, [10, 10, 0, 0, 0]], [112, 0, []],
      [122, 1, [10, 10, 1, 0, 1]], [111, 1, [1, 10, 0, 3, 1]],
      [113, 2, []], [412, 1, []], [413, 0, []]],
    'label' => [[119, 0, ['target']], [122, 0, [11, 11, 0, 0, 99]],
      [118, 0, ['target']], [122, 0, [11, 11, 0, 0, 66]]],
    'common-event' => [[117, 0, [1]]],
    'script-continuation' => [[355, 0, ['$game_variables[12] = 3']],
      [655, 0, ['$game_variables[12] *= 7']]],
    'comment-wait' => [[108, 0, ['comment']], [408, 0, ['continuation']],
      [230, 0, [3]], [122, 0, [13, 13, 0, 0, 88]]],
    'timer-start' => [[124, 0, [0, 5]]],
    'timer-stop' => [[124, 0, [1]]],
    'exit' => [[115, 0, []], [122, 0, [14, 14, 0, 0, 99]]],
    'switch-else' => [[111, 0, [0, 2, 0]], [122, 1, [6, 6, 0, 0, 99]],
      [411, 0, []], [122, 1, [6, 6, 0, 0, 77]], [412, 0, []]],
    'variable-else' => [[111, 0, [1, 1, 0, 100, 3]], [122, 1, [7, 7, 0, 0, 99]],
      [411, 0, []], [122, 1, [7, 7, 0, 0, 88]], [412, 0, []]],
    'self-switch-off' => [[123, 0, ['A', 1]], [111, 0, [2, 'A', 0]],
      [122, 1, [9, 9, 0, 0, 99]], [411, 0, []],
      [122, 1, [9, 9, 0, 0, 66]], [412, 0, []]],
    'variable-reference-branch' => [[111, 0, [1, 1, 1, 4, 0]],
      [122, 1, [14, 14, 0, 0, 22]], [412, 0, []]],
    'script-branch' => [[111, 0, [12, '$game_variables[12] == 21']],
      [122, 1, [14, 14, 1, 0, 3]], [412, 0, []]],
    'divide-by-zero' => [[122, 0, [1, 1, 4, 0, 0]]]
  }
  6.times do |comparison|
    [4, 5, 6].each do |value|
      cases["comparison-#{comparison}-#{value}"] = [
        [122, 0, [15, 15, 0, 0, value]], [111, 0, [1, 15, 0, 5, comparison]],
        [122, 1, [14, 14, 0, 0, 1]], [411, 0, []],
        [122, 1, [14, 14, 0, 0, 0]], [412, 0, []]]
    end
  end
  [0, 1].each do |comparison|
    [4, 5, 6].each do |seconds|
      cases["timer-condition-#{comparison}-#{seconds}"] = [
        [124, 0, [0, 5]], [111, 0, [3, seconds, comparison]],
        [122, 1, [14, 14, 0, 0, 1]], [411, 0, []],
        [122, 1, [14, 14, 0, 0, 0]], [412, 0, []]]
    end
  end
  cases['variable-fixed-random-range'] = [[122, 0, [14, 14, 0, 2, 7, 7]]]
  cases['modulo-by-zero'] = [[122, 0, [14, 14, 5, 0, 0]]]
  File.open(File.join(output, 'event_control_reference.tsv'), 'w') do |file|
    cases.each do |name, commands|
      list = commands.map { |code, indent, parameters| RPG::EventCommand.new(code, indent, parameters) }
      list << RPG::EventCommand.new
      interpreter = Game_Interpreter.new
      interpreter.setup(list, 4)
      updates = 0
      while interpreter.running?
        raise "event case hung: #{name}" if updates >= 100
        interpreter.update
        updates += 1
      end
      file.puts([name, updates, *(1..14).map { |id| $game_variables[id] },
        *(1..3).map { |id| $game_switches[id] }, $game_self_switches[[7, 4, 'A']],
        $game_timer.working?, $game_timer.sec].join("\t"))
      file.flush
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_control_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_message, $game_switches, $game_variables,
    $game_self_switches, $game_timer, $data_system, $data_common_events = saved
end
exit unless $rgss_compat_output
