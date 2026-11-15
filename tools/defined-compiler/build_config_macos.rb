MRuby::Build.new('macos-current') do |conf|
  conf.toolchain :clang
  conf.gembox 'default'
  conf.cc.defines = %w(MRB_CORE MRB_INT64 MRB_UTF8_STRING MRB_LIB)
  conf.cc.flags << '-fPIC'
  conf.enable_test
end
