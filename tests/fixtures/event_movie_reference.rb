output = $rgss_compat_output || '.'
saved = [$game_map, $game_message, $data_system]
begin
  $data_system = RPG::System.new
  $game_map = Game_Map.new
  $game_message = Game_Message.new
  File.open(File.join(output, 'event_movie_reference.tsv'), 'w') do |file|
    ['', ($event_movie_name || 'movie-reference.ogv')].each do |name|
      interpreter = Game_Interpreter.new
      interpreter.setup([RPG::EventCommand.new(261, 0, [name]), RPG::EventCommand.new])
      file.puts([name.empty? ? 'empty' : 'movie', 'before', interpreter.running?].join("\t"))
      file.flush
      while interpreter.running?
        interpreter.update
        Graphics.update
      end
      file.puts([name.empty? ? 'empty' : 'movie', 'after', interpreter.running?].join("\t"))
      file.flush
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_movie_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_message, $data_system = saved
end
exit unless $rgss_compat_output
