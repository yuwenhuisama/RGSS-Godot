output = $rgss_compat_output || '.'
unless $save_interchange_host
  DataManager.load_database
  DataManager.setup_new_game
end
module DataManager
  def self.make_filename(index)
    File.join($rgss_compat_output || '.', 'Save' + (index+1).to_s + '.rvdata2')
  end
end
$game_variables[1] = 31415
$game_switches[1] = true
$game_self_switches[[1,1,'A']] = true
$game_party.gain_gold(123)
$game_party.gain_item($data_items[1], 3)
$game_actors[1].name = 'Save actor'
$game_player.moveto(3,4)
DataManager.save_game_without_rescue(0)
File.open(File.join(output,'save_interchange_reference.tsv'),'w') do |file|
  file.puts ['saved',File.size(DataManager.make_filename(0)) > 0].join("\t")
  if $save_interchange_peer
    File.open($save_interchange_peer,'rb') do |stream|
      header = Marshal.load(stream)
      DataManager.extract_save_contents(Marshal.load(stream))
      file.puts ['header',header[:characters].size,header[:playtime_s].is_a?(String)].join("\t")
    end
    file.puts ['variable',$game_variables[1]].join("\t")
    file.puts ['switch',$game_switches[1],$game_self_switches[[1,1,'A']]].join("\t")
    file.puts ['party',$game_party.gold,$game_party.item_number($data_items[1])].join("\t")
    file.puts ['actor',$game_actors[1].name,$game_party.members[0].equal?($game_actors[1])].join("\t")
    file.puts ['player',$game_map.map_id,$game_player.x,$game_player.y].join("\t")
    3.times do
      $game_map.update(true)
      $game_player.update
      $game_timer.update
    end
    file.puts ['resumed',$game_map.map_id,$game_variables[1],$game_party.members[0].equal?($game_actors[1])].join("\t")
  end
end
exit unless $save_interchange_host
