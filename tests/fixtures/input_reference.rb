output=$rgss_compat_output || '.'
rows=[]
[:DOWN,:LEFT,:RIGHT,:UP,:A,:B,:C,:X,:Y,:Z,:L,:R,:SHIFT,:CTRL,:ALT,:F5,:F6,:F7,:F8,:F9].each do |name|
  begin
    rows << [name,Input.const_get(name).inspect,Input.press?(name),Input.trigger?(name),Input.repeat?(name)]
  rescue Exception=>error
    rows << [name,error.class.to_s]
  end
end
[:UNSUPPORTED,1,nil].each do |key|
  begin
    rows << ['invalid',key.inspect,Input.press?(key)]
  rescue Exception=>error
    rows << ['invalid',key.inspect,error.class.to_s]
  end
end
File.open(File.join(output,'input_reference.tsv'),'w'){|f|rows.each{|row|f.puts(row.join("\t"))}}
exit
