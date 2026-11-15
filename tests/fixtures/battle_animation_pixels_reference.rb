output=$rgss_compat_output || '.'
unless $battle_animation_pixels_host
  DataManager.load_database
  DataManager.create_game_objects
end
module Cache
  def self.animation(name,hue=0)
    image=Bitmap.new(384,192)
    image.fill_rect(56,56,80,80,Color.new(200,60,40))
    image.fill_rect(56,56,20,80,Color.new(40,180,80))
    image.fill_rect(248,56,80,80,Color.new(40,80,200))
    image.fill_rect(308,56,20,80,Color.new(220,180,40))
    image
  end
end
background=Sprite.new
background.z=-100
background.bitmap=Bitmap.new(544,416)
background.bitmap.fill_rect(background.bitmap.rect,Color.new(24,24,24))
sprite=Sprite_Base.new
sprite.bitmap=Bitmap.new(32,32)
sprite.x=240;sprite.y=192
animation=RPG::Animation.new
animation.position=1;animation.frame_max=2
animation.frames=[0,1].map do |pattern|
  frame=RPG::Animation::Frame.new
  frame.cell_max=1;frame.cell_data=Table.new(1,8)
  [pattern,0,0,100,0,0,255,0].each_with_index {|value,column|frame.cell_data[0,column]=value}
  frame
end
log=Window_BattleLog.new
log.add_text('Animation pixel contract')
File.open(File.join(output,'battle_animation_pixels.rgba'),'wb') do |file|
  [false,true].each do |mirror|
    sprite.start_animation(animation,mirror)
    8.times do |step|
      sprite.update
      Graphics.update
      if step==0 || step==4
        snapshot=Graphics.snap_to_bitmap
        bytes=[]
        160.times do |y|
          160.times do |x|
            pixel=snapshot.get_pixel(176+x,128+y)
            bytes.concat([pixel.red.to_i,pixel.green.to_i,pixel.blue.to_i,pixel.alpha.to_i])
          end
        end
        file.write(bytes.pack('C*'))
        snapshot.dispose
      end
    end
    sprite.dispose_animation
  end
end
log.add_text('Second battle log line')
log.contents_opacity=0
2.times { Graphics.update }
backdrop=Graphics.snap_to_bitmap
File.open(File.join(output,'battle_log_backdrop.tsv'),'w') do |file|
  [[44,16],[80,17],[500,16]].each do |x,y|
    pixel=backdrop.get_pixel(x,y)
    file.puts [x,y,pixel.red.to_i,pixel.green.to_i,pixel.blue.to_i,pixel.alpha.to_i].join("\t")
  end
end
backdrop.dispose
log.contents_opacity=255
File.open(File.join(output,'battle_log_contents.rgba'),'wb') do |file|
  64.times do |y|
    bytes=[]
    log.contents.width.times do |x|
      pixel=log.contents.get_pixel(x,y)
      bytes.concat([pixel.red.to_i,pixel.green.to_i,pixel.blue.to_i,pixel.alpha.to_i])
    end
    file.write(bytes.pack('C*'))
  end
end
2.times { Graphics.update }
snapshot=Graphics.snap_to_bitmap
File.open(File.join(output,'battle_log_pixels.rgba'),'wb') do |file|
  96.times do |y|
    bytes=[]
    544.times do |x|
      pixel=snapshot.get_pixel(x,y)
      bytes.concat([pixel.red.to_i,pixel.green.to_i,pixel.blue.to_i,pixel.alpha.to_i])
    end
    file.write(bytes.pack('C*'))
  end
end
snapshot.dispose
log.contents_opacity=0
probe=Window_Base.new(0,0,544,96)
probe.z=300
probe.opacity=0
[0,64,128,255].each_with_index do |value,row|
  256.times {|alpha|probe.contents.set_pixel(alpha,row,Color.new(value,value,value,alpha))}
end
2.times { Graphics.update }
sample=Graphics.snap_to_bitmap
File.open(File.join(output,'window_contents_alpha.tsv'),'w') do |file|
  4.times do |row|
    file.puts (0...256).map {|alpha|sample.get_pixel(alpha+probe.padding,row+probe.padding).red.to_i}.join("\t")
  end
end
sample.dispose;probe.dispose
log.dispose;sprite.bitmap.dispose;sprite.dispose
background.bitmap.dispose;background.dispose
exit unless $battle_animation_pixels_host
