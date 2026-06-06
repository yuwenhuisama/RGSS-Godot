MRuby::Gem::Specification.new('mruby-zlib') do |spec|
  spec.license = 'MIT'
  spec.authors = 'Internet Initiative Japan Inc.'

  if spec.mruby.cc.defines.include? 'ZLIB_STATIC'
    spec.cc.include_paths << "#{dir}/zlib"
    spec.cc.defines << 'HAVE_UNISTD_H' if build.toolchains.include? 'gcc'

    file "#{dir}/zlib" do
      sh 'curl -L --fail --retry 3 --retry-delay 1 http://zlib.net/zlib-1.2.11.tar.gz -s -o - | tar zxf -'
      mv 'zlib-1.2.11', "#{dir}/zlib"
    end

    Rake::Task["#{dir}/zlib"].invoke

    spec.objs += Dir["#{dir}/zlib/*.c"].map! do |f|
      f.relative_path_from(dir).pathmap("#{build_dir}/%X#{spec.exts.object}")
    end
  else
    spec.linker.libraries << 'z'
  end
end
