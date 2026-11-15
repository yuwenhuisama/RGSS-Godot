output = $rgss_compat_output || '.'
skin = Bitmap.new($window_layers_skin || 'Window.png')
if $window_layers_gradient
  skin.clear
  64.times { |y| skin.fill_rect(0,y,64,1,Color.new(y*4,y*4,y*4,255)) }
end
if $window_layers_parity
  skin.clear
  64.times do |y|
    value = y.odd? ? 255 : 0
    skin.fill_rect(0,y,64,1,Color.new(value,value,value,255))
  end
end
background = Bitmap.new(544,416)
background.fill_rect(background.rect,Color.new(0,0,0))
sprite = Sprite.new
sprite.bitmap = background
sprite.z = -1000
windows = []
skins = []
['stretch','tile','combined'].each_with_index do |mode,index|
  copy = Bitmap.new(128,128)
  copy.blt(0,0,skin,Rect.new(0,0,64,64)) unless mode == 'tile'
  copy.blt(0,64,skin,Rect.new(0,64,64,64)) unless mode == 'stretch'
  copy.blt(64,0,skin,Rect.new(64,0,64,64)) if $window_layers_border
  copy.blt(64,64,skin,Rect.new(64,64,32,32)) if $window_layers_cursor
  skins << copy
  window = Window.new(index*176,32,$window_layers_width || 168,$window_layers_height || 120)
  window.windowskin = copy
  window.back_opacity = $window_layers_opacity || 192
  window.contents_opacity = $window_layers_cursor ? ($window_layers_contents_opacity || 255) : 0
  window.active = false
  if $window_layers_cursor
    window.padding = 12
    contents = Bitmap.new(96,48)
    skins << contents
    window.contents = contents
    window.cursor_rect.set(0,0,96,24)
    window.active = false
    window.update
  end
  window.arrows_visible = false
  windows << window
end
8.times { Graphics.update }
snapshot = Graphics.snap_to_bitmap
File.open(File.join(output,'window_background_layers.rgba'),'wb') do |file|
  416.times do |y|
    row = []
    544.times do |x|
      color = snapshot.get_pixel(x,y)
      row.concat([color.red.to_i,color.green.to_i,color.blue.to_i,color.alpha.to_i])
    end
    file.write(row.pack('C*'))
  end
end
snapshot.dispose
windows.each { |window| window.dispose }
skins.each { |copy| copy.dispose }
sprite.dispose
background.dispose
skin.dispose
exit unless $window_layers_host
