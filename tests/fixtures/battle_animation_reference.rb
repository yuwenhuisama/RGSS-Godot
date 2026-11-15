output = $rgss_compat_output || '.'
unless $battle_animation_host
  DataManager.load_database
  DataManager.create_game_objects
end
animation = RPG::Animation.new
animation.frame_max=2
animation.frames=[RPG::Animation::Frame.new,RPG::Animation::Frame.new]
animation.frames.each { |frame| frame.cell_data[0,0]=-1 }
sprite=Sprite_Base.new
sprite.bitmap=Bitmap.new(32,32)
sprite.start_animation(animation)
File.open(File.join(output,'battle_animation_reference.tsv'),'w') do |file|
  10.times do |step|
    cells=sprite.instance_variable_get(:@ani_sprites)
    file.puts ['animation',step,sprite.animation?,sprite.instance_variable_get(:@ani_duration),cells ? cells.size : 0].join("\t")
    sprite.update
  end
  log=Window_BattleLog.new
  log.add_text('First line')
  log.add_text('Second line')
  file.puts ['log-add',log.line_number,log.instance_variable_get(:@lines).join('|')].join("\t")
  log.back_one
  file.puts ['log-back',log.line_number,log.instance_variable_get(:@lines).join('|')].join("\t")
  log.clear
  file.puts ['log-clear',log.line_number].join("\t")
  log.dispose
  frame=RPG::Animation::Frame.new
  frame.cell_max=1
  frame.cell_data=Table.new(1,8)
  [0,12,-8,75,30,0,160,1].each_with_index { |value,column| frame.cell_data[0,column]=value }
  animation.frames=[frame,frame]
  sprite.x=100
  sprite.y=120
  sprite.z=40
  sprite.opacity=128
  [false,true].each do |mirror|
    sprite.start_animation(animation,mirror)
    sprite.update
    cell=sprite.instance_variable_get(:@ani_sprites)[0]
    file.puts ['cell',mirror,cell.visible,cell.x,cell.y,cell.z,cell.ox,cell.oy,cell.zoom_x,cell.angle,cell.mirror,cell.opacity,cell.blend_type].join("\t")
    sprite.dispose_animation
  end
  viewport=Viewport.new(0,0,64,64)
  timing_sprite=Sprite_Base.new(viewport)
  class << timing_sprite
    attr_accessor :flash_calls
    def flash(color,duration)
      self.flash_calls ||= []
      flash_calls << [color.nil? ? 'hide' : 'color',duration]
      super
    end
  end
  class << viewport
    attr_accessor :flash_calls
    def flash(color,duration)
      self.flash_calls ||= []
      flash_calls << ['color',duration]
      super
    end
  end
  [1,2,3].each do |scope|
    timing=RPG::Animation::Timing.new
    timing.flash_scope=scope
    timing.flash_duration=3
    animation.timings=[timing]
    timing_sprite.flash_calls=[];viewport.flash_calls=[]
    timing_sprite.start_animation(animation)
    timing_sprite.update
    file.puts ['timing-flash',scope,timing_sprite.flash_calls.flatten.join(','),viewport.flash_calls.flatten.join(',')].join("\t")
    timing_sprite.dispose_animation
  end
  timing_sprite.dispose;viewport.dispose
end
sprite.bitmap.dispose
sprite.dispose
exit unless $battle_animation_host
