output=$rgss_compat_output || '.'
rows=[]
Graphics.frame_count=123
Graphics.frame_reset
rows << ['frame_reset',Graphics.frame_count]
Graphics.frame_count=0
[0,1,4,-1].each do |duration|
  before=Graphics.frame_count
  Graphics.wait(duration)
  rows << ['wait',duration,Graphics.frame_count-before]
end
[0,1,4].each do |duration|
  before=Graphics.frame_count
  Graphics.fadeout(duration)
  rows << ['fadeout',duration,Graphics.frame_count-before,Graphics.brightness]
  before=Graphics.frame_count
  Graphics.fadein(duration)
  rows << ['fadein',duration,Graphics.frame_count-before,Graphics.brightness]
end
File.open(File.join(output,'graphics_frame_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
exit
