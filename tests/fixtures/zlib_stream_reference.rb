output = $rgss_compat_output || '.'
File.open(File.join(output, 'zlib_stream_interfaces.tsv'), 'w') do |file|
  [Zlib::ZStream, Zlib::Deflate, Zlib::Inflate].each do |type|
    file.puts [type.name, type.instance_methods(false).map { |name| name.to_s }.sort.join(',')].join("\t")
  end
end
File.open(File.join(output, 'zlib_stream_reference.tsv'), 'w') do |file|
  probes = [
    ['deflate-close-wrapped-unfinished', proc do
      stream = Zlib::Deflate.new
      stream.deflate('payload', Zlib::SYNC_FLUSH)
      stream.close
    end],
    ['deflate-params-continue', proc do
      stream = Zlib::Deflate.new
      bytes = stream.deflate('native ', Zlib::SYNC_FLUSH)
      begin
        stream.params(0, 0)
      rescue Zlib::StreamError
      end
      begin
        bytes += stream.deflate('payload', Zlib::FINISH)
        Zlib::Inflate.inflate(bytes)
      ensure
        stream.close
      end
    end],
    ['raw-sync-bytes', proc do
      stream = Zlib::Deflate.new(-1, -15)
      begin
        bytes = stream.deflate('payload', Zlib::SYNC_FLUSH).unpack('H*')[0]
        stream.finish
        bytes
      ensure
        stream.close
      end
    end],
    ['inflate-sync-point-positive', proc do
      compressor = Zlib::Deflate.new(-1, -15)
      stream = Zlib::Inflate.new(-15)
      begin
        bytes = compressor.deflate('payload', Zlib::SYNC_FLUSH)
        text = stream.inflate(bytes[0, bytes.bytesize - 4])
        compressor.finish
        [text, stream.sync_point?].join(',')
      ensure
        compressor.close
        stream.close
      end
    end],
    ['deflate-close-unfinished', proc do
      stream = Zlib::Deflate.new(-1, -15)
      stream.deflate('payload', Zlib::SYNC_FLUSH)
      stream.close
    end],
    ['inflate-sync-raw-recovery', proc do
      compressor = Zlib::Deflate.new(-1, -15)
      stream = Zlib::Inflate.new(-15)
      begin
        first = compressor.deflate('discard', Zlib::FULL_FLUSH)
        last = compressor.deflate('payload', Zlib::FINISH)
        [stream.sync('junk' + first), stream.inflate(last), stream.finished?].join(',')
      ensure
        compressor.close
        stream.close
      end
    end],
    ['stream-capacity-reset', proc do
      stream = Zlib::Deflate.new
      begin
        stream.avail_out = 128
        stream.reset
        stream.avail_out
      ensure
        stream.close
      end
    end],
    ['deflate-params', proc do
      stream = Zlib::Deflate.new
      begin
        bytes = stream.deflate('native ', Zlib::SYNC_FLUSH)
        stream.avail_out = 1024
        changed = stream.params(0, 0)
        bytes += stream.deflate('payload', Zlib::FINISH)
        [changed.nil?, Zlib::Inflate.inflate(bytes)].join(',')
      ensure
        stream.close
      end
    end],
    ['deflate-params-invalid', proc do
      stream = Zlib::Deflate.new
      begin
        stream.params(10, 0)
      ensure
        stream.close
      end
    end],
    ['deflate-params-no-capacity', proc do
      stream = Zlib::Deflate.new
      stream.deflate('native ', Zlib::SYNC_FLUSH)
      parameter_error = ''
      close_error = ''
      begin
        stream.params(0, 0)
      rescue StandardError => error
        parameter_error = error.class.to_s
      end
      begin
        stream.close
      rescue StandardError => error
        close_error = error.class.to_s
      end
      [parameter_error, close_error].join(',')
    end],
    ['inflate-sync-point', proc do
      stream = Zlib::Inflate.new
      begin
        stream.sync_point?
      ensure
        stream.close
      end
    end],
    ['inflate-sync-missing', proc do
      stream = Zlib::Inflate.new
      begin
        stream.sync('junk')
      ensure
        stream.close
      end
    end],
    ['inflate-sync-recovery', proc do
      compressor = Zlib::Deflate.new
      stream = Zlib::Inflate.new
      begin
        first = compressor.deflate('discard', Zlib::FULL_FLUSH)
        last = compressor.deflate('payload', Zlib::FINISH)
        found = stream.sync('junk' + first)
        text = ''
        error_type = ''
        begin
          text = stream.inflate(last)
        rescue Zlib::DataError => error
          error_type = error.class.to_s
        end
        [found, text, error_type].join(',')
      ensure
        compressor.close
        stream.close
      end
    end],
    ['stream-state-aliases', proc do
      stream = Zlib::Deflate.new
      before = [stream.ended?, stream.stream_end?]
      stream.deflate('payload', Zlib::FINISH)
      finished = stream.stream_end?
      stream.end
      [*before, finished, stream.ended?].join(',')
    end],
    ['stream-buffer-state', proc do
      stream = Zlib::Deflate.new
      begin
        [stream.avail_in, stream.avail_out, stream.data_type, stream.flush_next_in.bytesize, stream.flush_next_out.bytesize].join(',')
      ensure
        stream.close
      end
    end],
    ['stream-flush-output', proc do
      stream = Zlib::Deflate.new
      begin
        stream << 'payload'
        first = stream.flush_next_out
        second = stream.flush_next_out
        bytes = first + stream.finish
        [Zlib::Inflate.inflate(bytes), second.bytesize].join(',')
      ensure
        stream.close
      end
    end],
    ['inflate-flush-input', proc do
      stream = Zlib::Inflate.new
      begin
        stream.inflate(Zlib::Deflate.deflate('payload') + 'tail')
        [stream.avail_in, stream.flush_next_in, stream.flush_next_in, stream.finish].join(',')
      ensure
        stream.close
      end
    end],
    ['stream-output-capacity', proc do
      stream = Zlib::Deflate.new
      begin
        initial = stream.avail_out
        stream.avail_out = 128
        assigned = stream.avail_out
        bytes = stream.deflate('payload', Zlib::FINISH)
        [initial, assigned, stream.avail_out, Zlib::Inflate.inflate(bytes)].join(',')
      ensure
        stream.close
      end
    end],
    ['deflate-append', proc do
      stream = Zlib::Deflate.new
      begin
        same = (stream << 'native ' << 'payload').equal?(stream)
        [same, Zlib::Inflate.inflate(stream.finish)].join(',')
      ensure
        stream.close
      end
    end],
    ['inflate-append', proc do
      stream = Zlib::Inflate.new
      begin
        same = (stream << Zlib::Deflate.deflate('payload')).equal?(stream)
        [same, stream.finish].join(',')
      ensure
        stream.close
      end
    end],
    ['inflate-later-tail', proc do
      stream = Zlib::Inflate.new
      begin
        text = stream.inflate(Zlib::Deflate.deflate('payload') + 'first')
        extra = stream.inflate('second')
        [text, extra, stream.finish].join(',')
      ensure
        stream.close
      end
    end],
    ['deflate-block-open', proc do
      captured = nil
      result = Zlib::Deflate.open do |stream|
        captured = stream
        Zlib::Inflate.inflate(stream.deflate('payload', Zlib::FINISH))
      end
      [result, captured.closed?].join(',')
    end],
    ['inflate-dictionary-retained-input', proc do
      dictionary = 'native payload dictionary'
      compressor = Zlib::Deflate.new
      stream = Zlib::Inflate.new
      begin
        compressor.set_dictionary(dictionary)
        bytes = compressor.deflate('native payload', Zlib::FINISH)
        begin
          stream.inflate(bytes)
        rescue Zlib::NeedDict
        end
        stream.set_dictionary(dictionary)
        [stream.inflate(''), stream.finished?].join(',')
      ensure
        compressor.close
        stream.close
      end
    end],
    ['inflate-trailing-input', proc do
      stream = Zlib::Inflate.new
      begin
        text = stream.inflate(Zlib::Deflate.deflate('payload') + 'tail')
        [text, stream.finish].join(',')
      ensure
        stream.close
      end
    end],
    ['deflate-flush-method', proc do
      compressor = Zlib::Deflate.new
      stream = Zlib::Inflate.new
      begin
        bytes = compressor.deflate('native ') + compressor.flush(Zlib::SYNC_FLUSH)
        first = stream.inflate(bytes)
        [first, stream.inflate(compressor.deflate('payload', Zlib::FINISH))].join(',')
      ensure
        compressor.close
        stream.close
      end
    end],
    ['deflate-dictionary', proc do
      dictionary = 'native payload dictionary'
      stream = Zlib::Deflate.new
      begin
        returned = stream.set_dictionary(dictionary)
        bytes = stream.deflate('native payload', Zlib::FINISH)
        [returned == dictionary, bytes.unpack('H*')[0], stream.adler].join(',')
      ensure
        stream.close
      end
    end],
    ['inflate-dictionary', proc do
      dictionary = 'native payload dictionary'
      compressor = Zlib::Deflate.new
      stream = Zlib::Inflate.new
      begin
        compressor.set_dictionary(dictionary)
        bytes = compressor.deflate('native payload', Zlib::FINISH)
        needed = ''
        begin
          stream.inflate(bytes[0, 6])
        rescue Zlib::NeedDict => error
          needed = error.class.to_s
        end
        checksum = stream.adler
        returned = stream.set_dictionary(dictionary)
        text = stream.inflate(bytes[6, bytes.bytesize - 6])
        [needed, checksum == Zlib.adler32(dictionary), returned == dictionary, text, stream.finished?].join(',')
      ensure
        compressor.close
        stream.close
      end
    end],
    ['inflate-wrong-dictionary', proc do
      dictionary = 'native payload dictionary'
      compressor = Zlib::Deflate.new
      stream = Zlib::Inflate.new
      begin
        compressor.set_dictionary(dictionary)
        bytes = compressor.deflate('native payload', Zlib::FINISH)
        begin
          stream.inflate(bytes[0, 6])
        rescue Zlib::NeedDict
        end
        stream.set_dictionary('wrong')
      ensure
        compressor.close
        stream.close
      end
    end],
    ['deflate-sync-flush', proc do
      compressor = Zlib::Deflate.new
      stream = Zlib::Inflate.new
      begin
        first = compressor.deflate('native ', Zlib::SYNC_FLUSH)
        text = stream.inflate(first)
        complete = compressor.deflate('payload', Zlib::FINISH)
        [text, stream.inflate(complete), stream.finished?].join(',')
      ensure
        compressor.close
        stream.close
      end
    end],
    ['large-chunks', proc do
      text = 'payload' * 4000
      compressed = Zlib::Deflate.new(0)
      decompressed = Zlib::Inflate.new
      begin
        bytes = compressed.deflate(text, Zlib::FINISH)
        result = decompressed.inflate(bytes)
        [result == text, decompressed.total_out, compressed.total_in].join(',')
      ensure
        compressed.close
        decompressed.close
      end
    end],
    ['deflate-nil-finish', proc do
      stream = Zlib::Deflate.new
      begin
        bytes = stream.deflate('payload') + stream.deflate(nil)
        [Zlib::Inflate.inflate(bytes), stream.finished?].join(',')
      ensure
        stream.close
      end
    end],
    ['inflate-finish-complete', proc do
      stream = Zlib::Inflate.new
      begin
        stream.inflate(Zlib::Deflate.deflate('payload'))
        stream.finish.bytesize
      ensure
        stream.close
      end
    end],
    ['inflate-reset', proc do
      stream = Zlib::Inflate.new
      begin
        stream.inflate(Zlib::Deflate.deflate('first'))
        stream.reset
        [stream.inflate(Zlib::Deflate.deflate('second')), stream.total_out].join(',')
      ensure
        stream.close
      end
    end],
    ['stream-double-close', proc do
      stream = Zlib::Deflate.new
      stream.close
      stream.close
    end],
    ['deflate-invalid-level', proc { Zlib::Deflate.new(10) }],
    ['inflate-invalid-window', proc { Zlib::Inflate.new(100) }],
    ['deflate-chunks', proc do
      stream = Zlib::Deflate.new
      begin
        bytes = stream.deflate('native ', Zlib::NO_FLUSH) + stream.deflate('payload', Zlib::FINISH)
        [Zlib::Inflate.inflate(bytes), stream.finished?, stream.total_in, stream.total_out == bytes.bytesize].join(',')
      ensure
        stream.close
      end
    end],
    ['inflate-chunks', proc do
      bytes = Zlib::Deflate.deflate('native payload')
      stream = Zlib::Inflate.new
      begin
        text = stream.inflate(bytes[0, 5]) + stream.inflate(bytes[5, bytes.bytesize - 5])
        [text, stream.finished?, stream.total_in == bytes.bytesize, stream.total_out].join(',')
      ensure
        stream.close
      end
    end],
    ['deflate-finish', proc do
      stream = Zlib::Deflate.new
      begin
        bytes = stream.deflate('payload') + stream.finish
        [Zlib::Inflate.inflate(bytes), stream.finished?].join(',')
      ensure
        stream.close
      end
    end],
    ['inflate-finish-truncated', proc do
      stream = Zlib::Inflate.new
      begin
        bytes = Zlib::Deflate.deflate('payload')
        stream.inflate(bytes[0, bytes.bytesize - 3])
        stream.finish
      ensure
        stream.close
      end
    end],
    ['deflate-reset', proc do
      stream = Zlib::Deflate.new
      begin
        stream.deflate('first', Zlib::FINISH)
        stream.reset
        bytes = stream.deflate('second', Zlib::FINISH)
        [Zlib::Inflate.inflate(bytes), stream.total_in].join(',')
      ensure
        stream.close
      end
    end],
    ['stream-close', proc do
      stream = Zlib::Deflate.new
      before = stream.closed?
      stream.close
      [before, stream.closed?].join(',')
    end],
    ['stream-after-close', proc do
      stream = Zlib::Inflate.new
      stream.close
      stream.inflate('payload')
    end]
  ]
  probes.each do |name, probe|
    begin
      file.puts [name, probe.call].join("\t")
    rescue StandardError => error
      file.puts [name, 'error', error.class].join("\t")
    end
    file.flush
  end
end
exit unless $zlib_stream_host
