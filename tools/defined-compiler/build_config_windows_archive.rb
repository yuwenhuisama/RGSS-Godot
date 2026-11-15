MRuby::Build.new do |conf|
  conf.toolchain :visualcpp
  conf.gembox 'default'
  conf.cc.defines = %w(MRB_CORE MRB_INT64 MRB_UTF8_STRING MRB_USE_DEBUG_HOOK MRB_LIB)
  conf.build_dir = File.expand_path('mruby/build/host-dll', __dir__)
  conf.enable_test
end
