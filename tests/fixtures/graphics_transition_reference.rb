output=$rgss_compat_output || '.'
bitmap=Bitmap.new(544,416);bitmap.fill_rect(bitmap.rect,Color.new(160,80,40,255))
sprite=Sprite.new;sprite.bitmap=bitmap
$transition_rows=[]
if Object.const_defined?(:Unity)
  def Graphics.__rgss_transition_mask(filename)
    filename.nil? || filename.empty? ? nil : Bitmap.new(filename)
  end
end
module Graphics
  class << self
    alias compatibility_update update
    def update
      compatibility_update
      if $capture_transition
        snap=snap_to_bitmap
        points=[[80,80],[272,208],[460,340]].map {|x,y|c=snap.get_pixel(x,y);[c.red,c.green,c.blue,c.alpha].join(',')}
        $transition_rows << [$transition_mode,*points];snap.dispose
        if $capture_transition_pixels
          image=Graphics.snap_to_bitmap
          File.open(File.join($rgss_compat_output,'graphics_transition_frames.rgba'),'ab') do |file|
            416.times do |y|
              bytes=[];544.times {|x|c=image.get_pixel(x,y);bytes.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
              file.write(bytes.pack('C*'))
            end
          end
          image.dispose
        end
      end
    end
  end
end
4.times {Graphics.update}
Graphics.wait(600) if $record_transition_video
Graphics.freeze
bitmap.fill_rect(bitmap.rect,Color.new(20,180,240,255))
$capture_transition=true;$transition_mode='mask'
Graphics.transition(($record_transition_video || $capture_transition_pixels) ? 60 : 8,TestPaths.rtp('Graphics/System/BattleStart.png'),40)
$capture_transition=false
snap=Graphics.snap_to_bitmap;c=snap.get_pixel(272,208);$transition_rows << ['mask_end',c.red,c.green,c.blue,c.alpha];snap.dispose
2.times {Graphics.update}
Graphics.wait(600) if $record_transition_video
Graphics.freeze
bitmap.fill_rect(bitmap.rect,Color.new(160,80,40,255))
$capture_transition=true;$transition_mode='plain'
Graphics.transition(($record_transition_video || $capture_transition_pixels) ? 60 : 8)
$capture_transition=false
Graphics.wait(600) if $record_transition_video
snap=Graphics.snap_to_bitmap;c=snap.get_pixel(272,208);$transition_rows << ['plain_end',c.red,c.green,c.blue,c.alpha];snap.dispose
File.open(File.join(output,'graphics_transition_reference.tsv'),'w') {|file|$transition_rows.each {|row|file.puts(row.join("\t"))}}
sprite.dispose;bitmap.dispose
exit
