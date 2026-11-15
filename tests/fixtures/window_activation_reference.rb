output=$rgss_compat_output || '.'
background=Bitmap.new(544,416)
background.fill_rect(background.rect,Color.new(0,0,0))
sprite=Sprite.new;sprite.bitmap=background
skin=Bitmap.new(128,128)
skin.fill_rect(64,64,32,32,Color.new(255,255,255))
window=Window.new(40,40,96,80)
window.windowskin=skin
window.cursor_rect.set(16,16,32,24)
window.active=false
File.open(File.join(output,'window_activation_reference.tsv'),'w') do |file|
  [[:inactive,12],[:activated,24],[:inactive_again,7],[:reactivated,24]].each do |name,count|
    window.active=(name==:activated || name==:reactivated)
    count.times do |frame|
      window.update
      2.times { Graphics.update }
      snapshot=Graphics.snap_to_bitmap
      c=snapshot.get_pixel(72,72)
      file.puts([name,frame,c.red.to_i,c.green.to_i,c.blue.to_i].join("\t"))
      snapshot.dispose
    end
  end
end
window.dispose;skin.dispose;sprite.dispose;background.dispose
exit
