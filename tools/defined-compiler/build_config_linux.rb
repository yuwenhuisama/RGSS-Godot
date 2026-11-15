MRuby::Build.new('linux-current') do |conf|
  conf.toolchain :gcc
  conf.gembox 'default'
  conf.cc.defines = %w(MRB_CORE MRB_INT64 MRB_UTF8_STRING MRB_LIB)
  conf.cc.flags << '-fPIC'
  conf.enable_test
end
