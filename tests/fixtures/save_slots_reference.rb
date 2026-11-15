output = $rgss_compat_output || '.'
unless $save_slots_host
  DataManager.load_database
  DataManager.setup_new_game
end
module DataManager
  def self.make_filename(index)
    File.join($rgss_compat_output || '.', 'Slots' + index.to_s + '.rvdata2')
  end
end
File.open(File.join(output,'save_slots_reference.tsv'),'w') do |file|
  File.delete(DataManager.make_filename(1)) if File.exist?(DataManager.make_filename(1))
  file.puts ['missing',DataManager.load_header(1).nil?,DataManager.load_game(1)].join("\t")
  $game_variables[1] = 111
  file.puts ['first-save',DataManager.save_game(0),DataManager.last_savefile_index].join("\t")
  header = DataManager.load_header(0)
  file.puts ['header',header[:characters].size,header[:playtime_s].is_a?(String)].join("\t")
  $game_variables[1] = 222
  file.puts ['overwrite',DataManager.save_game(0)].join("\t")
  $game_variables[1] = 333
  result = DataManager.load_game(0)
  file.puts ['load-overwrite',result,$game_variables[1],DataManager.last_savefile_index].join("\t")
  File.open(DataManager.make_filename(1),'wb') { |stream| stream.write('broken') }
  file.puts ['corrupt',DataManager.load_header(1).nil?,DataManager.load_game(1),$game_variables[1]].join("\t")
  File.open(DataManager.make_filename(1),'wb') { |stream| Marshal.dump(header,stream) }
  file.puts ['header-only',DataManager.load_header(1).is_a?(Hash),DataManager.load_game(1),$game_variables[1]].join("\t")
  DataManager.delete_save_file(1)
  file.puts ['delete',File.exist?(DataManager.make_filename(1))].join("\t")
  file.flush
end
exit unless $save_slots_host
