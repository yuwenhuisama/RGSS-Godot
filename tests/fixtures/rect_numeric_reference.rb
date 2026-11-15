output = $rgss_compat_output || '.'
File.open(File.join(output, 'rect_numeric_reference.tsv'), 'w') do |file|
  [1.9, -1.9].each do |value|
    [:new, :set, :x, :y, :width, :height].each do |operation|
      begin
        rect = Rect.new(0, 0, 0, 0)
        case operation
        when :new then rect = Rect.new(value, value, value, value)
        when :set then rect.set(value, value, value, value)
        else rect.send(operation.to_s + '=', value)
        end
        file.puts [operation, value, rect.x, rect.y, rect.width, rect.height].join("\t")
      rescue Exception => error
        file.puts [operation, value, error.class].join("\t")
      end
      file.flush
    end
  end
end
exit unless $rect_numeric_host
