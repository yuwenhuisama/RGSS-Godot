output=$rgss_compat_output || '.'
bitmap=Bitmap.new(544,416);bitmap.fill_rect(bitmap.rect,Color.new(160,80,40,255))
sprite=Sprite.new;sprite.bitmap=bitmap
rows=[]
def graphics_reference_row(rows,name)
  snap=Graphics.snap_to_bitmap;c=snap.get_pixel(100,100)
  rows << [name,Graphics.brightness,c.red,c.green,c.blue,c.alpha];snap.dispose
end
4.times {Graphics.update}
graphics_reference_row(rows,'plain')
Graphics.freeze
bitmap.fill_rect(bitmap.rect,Color.new(20,180,240,255))
4.times {Graphics.update}
graphics_reference_row(rows,'frozen')
Graphics.transition(4)
graphics_reference_row(rows,'transition_end')
2.times {Graphics.update}
graphics_reference_row(rows,'after_transition')
Graphics.brightness=128
2.times {Graphics.update}
graphics_reference_row(rows,'brightness128')
Graphics.fadeout(4)
graphics_reference_row(rows,'fadeout_end')
Graphics.fadein(4)
graphics_reference_row(rows,'fadein_end')
File.open(File.join(output,'graphics_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
sprite.dispose;bitmap.dispose
exit
