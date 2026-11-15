output = $rgss_compat_output || '.'
$runtime_defined_side_effect = 0
File.open(File.join(output,'ruby_runtime_reference.tsv'),'w') do |file|
  probes = [
    ['defined-constant','defined?(Object)'],
    ['defined-missing','defined?(RGSSMissingRuntimeConstant)'],
    ['defined-method','defined?(puts)'],
    ['defined-global','defined?($runtime_defined_side_effect)'],
    ['defined-side-effect','defined?($runtime_defined_side_effect += 1)'],
    ['integer-division','-7 / 3'],
    ['modulo','-7 % 3'],
    ['utf8-length','"中文".length'],
    ['binary-length','"中文".force_encoding("ASCII-8BIT").length'],
    ['encoding-switch-back','text="中文"; text.force_encoding("ASCII-8BIT"); bytes=text.length; text.force_encoding("UTF-8"); [bytes,text.length].join(",")'],
    ['sort-float','[3,1,2].sort { |a,b| (a-b)*0.5 }.join(",")'],
    ['string-format','sprintf("%03d:%.2f",7,1.25)'],
    ['regexp-capture','/(a)(b)/.match("ab")[2]'],
    ['block-return','[1,2,3].find { |number| number > 1 }'],
    ['symbol-hash','{:value=>42}[:value]']
  ]
  probes.each do |probe|
    begin
      result = eval(probe[1])
      file.puts [probe[0],result.nil? ? 'nil' : result.to_s].join("\t")
    rescue StandardError => error
      file.puts [probe[0],'error',error.class].join("\t")
    end
  end
  file.puts ['defined-side-effect-count',$runtime_defined_side_effect].join("\t")
end
exit unless $ruby_runtime_host
