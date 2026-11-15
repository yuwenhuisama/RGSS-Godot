output = $rgss_compat_output || '.'
read_index = lambda do |table, indices|
  begin
    table[*indices].inspect
  rescue ArgumentError => error
    error.class.to_s + ':' + error.message
  end
end
File.open(File.join(output, 'table_dimensions_reference.tsv'), 'w') do |file|
  [[3], [3,2], [3,2,2], [3,0], [3,0,0], [0,0]].each do |args|
    table = Table.new(*args)
    file.puts [args.join(','), 'new', table.xsize, table.ysize, table.zsize,
      read_index.call(table,[0]), read_index.call(table,[0,0]), read_index.call(table,[0,0,0]),
      table._dump(0).unpack('C*')[0,20].join(',')].join("\t")
    table.resize(4,3)
    file.puts [args.join(','), 'resize', table.xsize, table.ysize, table.zsize,
      read_index.call(table,[0]), read_index.call(table,[0,0]), read_index.call(table,[0,0,0]),
      table._dump(0).unpack('C*')[0,20].join(',')].join("\t")
    file.flush
  end
end
exit unless $table_dimensions_host
