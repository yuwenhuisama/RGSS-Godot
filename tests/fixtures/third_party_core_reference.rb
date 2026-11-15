output=$rgss_compat_output || '.'
unless $third_party_core_host
  DataManager.load_database
  DataManager.create_game_objects
end
File.open(File.join(output,'third_party_core_reference.tsv'),'w') do |file|
  file.puts ['imported',$imported['YEA-CoreEngine']].join("\t")
  file.puts ['resolution',Graphics.width,Graphics.height].join("\t")
  [-1234567,0,1234567,12345.5].each {|number|file.puts ['group',number,number.group].join("\t")}
  sprite=Sprite_Base.new
  animation=RPG::Animation.new
  animation.frame_max=2
  sprite.start_pseudo_animation(animation)
  file.puts ['animation-rate',sprite.instance_variable_get(:@ani_rate),sprite.instance_variable_get(:@ani_duration)].join("\t")
  sprite.dispose
  window=Window_Base.new(0,0,320,96)
  file.puts ['font',window.contents.font.size,window.contents.font.bold,window.contents.font.italic,window.translucent_alpha].join("\t")
  window.contents.clear
  window.draw_gauge(0,0,100,1.5,Color.new(255,0,0),Color.new(255,0,0))
  file.puts ['gauge-cap',window.contents.get_pixel(98,12).red.to_i,window.contents.get_pixel(101,12).alpha.to_i].join("\t")
  window.dispose
  $game_party.setup_starting_members
  file.puts ['party',$game_party.members.size].join("\t")
  actor=$game_party.members[0]
  actor.make_actions
  saved=actor.actions.dup
  actor.force_action(1,0)
  actor.restore_cloned_actions
  file.puts ['forced-restore',actor.actions.size,actor.actions[0].equal?(saved[0])].join("\t")
end
exit unless $third_party_core_host
