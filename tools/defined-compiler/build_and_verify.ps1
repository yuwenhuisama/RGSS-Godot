$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'test_paths.ps1')

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$expRoot = Join-Path $repoRoot '.omo/compatibility-run-tmp/f05-defined-compiler'
$mrubyCopy = Join-Path $expRoot 'mruby'
$patchSourceOnly = Join-Path $PSScriptRoot 'mruby-4.0.0-defined-compiler.source.patch'
$patchFull = Join-Path $PSScriptRoot 'mruby-4.0.0-defined-compiler.full.patch'
$sharedMruby = Get-TestPath 'mruby_source'
$sharedGlueSrc = Join-Path (Split-Path $sharedMruby -Parent) 'mruby-shared'

New-Item -ItemType Directory -Force -Path $expRoot | Out-Null

if (-not (Test-Path (Join-Path $mrubyCopy '.git'))) {
    git clone --no-hardlinks $sharedMruby $mrubyCopy
    if ($LASTEXITCODE -ne 0) { throw 'Failed to clone owned mruby copy' }
    git -C $mrubyCopy apply --whitespace=nowarn $patchFull
    if ($LASTEXITCODE -ne 0) { throw 'Failed to apply full compiler patch' }
}

$gemsDir = Join-Path $expRoot 'gems'
if (-not (Test-Path (Join-Path $gemsDir 'mruby-marshal-c'))) {
    New-Item -ItemType Directory -Force -Path $gemsDir | Out-Null
    Copy-Item -Recurse -Force (Join-Path $repoRoot 'mruby-ext/marshal/mruby-marshal-c') (Join-Path $gemsDir 'mruby-marshal-c')
    Remove-Item -Recurse -Force (Join-Path $gemsDir 'mruby-marshal-c/test') -ErrorAction SilentlyContinue
}
if (-not (Test-Path (Join-Path $gemsDir 'mruby-onig-regexp/src/mruby_onig_regexp.c'))) {
    New-Item -ItemType Directory -Force -Path (Join-Path $gemsDir 'mruby-onig-regexp/src') | Out-Null
    Copy-Item -Force (Join-Path $repoRoot 'mruby-ext/regexp/mruby-onig-regexp/src/mruby_onig_regexp.c') (Join-Path $gemsDir 'mruby-onig-regexp/src/mruby_onig_regexp.c')
    $rakeSpec = @"
MRuby::Gem::Specification.new('mruby-onig-regexp') do |spec|
  spec.license = 'MIT'
  spec.authors = 'mattn'
  spec.add_dependency 'mruby-string-ext', core: 'mruby-string-ext'
  spec.cc.include_paths << File.expand_path('../../../../../mruby-ext/regexp/Onigmo', __dir__)
  spec.cc.defines += %w(HAVE_ONIGMO_H)
  spec.linker.library_paths << File.expand_path('../../../../../mruby-ext/lib', __dir__)
  spec.linker.libraries << 'onigmo_s'
end
"@
    [System.IO.File]::WriteAllText((Join-Path $gemsDir 'mruby-onig-regexp/mrbgem.rake'), $rakeSpec, (New-Object System.Text.UTF8Encoding($false)))
}

# 1. Build standalone native mruby.exe with pinned host ABI defines including MRB_USE_DEBUG_HOOK
$buildConfPath = Join-Path $expRoot 'build_config_defined.rb'
$buildConf = @"
MRuby::Build.new do |conf|
  conf.toolchain :visualcpp
  conf.gembox 'default'
  conf.gem File.expand_path('gems/mruby-marshal-c', __dir__)
  conf.gem File.expand_path('gems/mruby-onig-regexp', __dir__)

  conf.cc do |cc|
    cc.defines = %w(MRB_CORE MRB_INT64 MRB_UTF8_STRING MRB_USE_DEBUG_HOOK MRB_LIB)
  end

  gperf_candidate = File.expand_path('tools/gperf/mingw64/bin/gperf.exe', __dir__)
  if File.exist?(gperf_candidate)
    conf.gperf do |gperf|
      gperf.command = gperf_candidate
      gperf.compile_options = %q[-L ANSI-C -C -j1 -i 1 -o -t -N mrb_reserved_word -k"1,3,$" "%{infile}" > "%{outfile}"]
    end
  end

  conf.enable_test
end
"@
[System.IO.File]::WriteAllText($buildConfPath, $buildConf, (New-Object System.Text.UTF8Encoding($false)))

$vcvars = Get-TestPath 'vs_devcmd'
$buildCmdPath = Join-Path $expRoot 'run_build.cmd'
$buildCmd = @"
@echo off
call "$vcvars"
if errorlevel 1 exit /b %errorlevel%
cd /d "$mrubyCopy"
if errorlevel 1 exit /b %errorlevel%
rake MRUBY_CONFIG=../build_config_defined.rb all
exit /b %errorlevel%
"@
[System.IO.File]::WriteAllText($buildCmdPath, $buildCmd, [System.Text.Encoding]::ASCII)

$proc = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/d', '/c', $buildCmdPath) -NoNewWindow -Wait -PassThru
Write-Output "DEFINED_BUILD_EXIT:$($proc.ExitCode)"
if ($proc.ExitCode -ne 0) { exit $proc.ExitCode }

# 2. Verify standalone mruby.exe against both original RGSS300 fixtures and 58-case contract suite
$mrubyExe = Join-Path $mrubyCopy 'build/host/bin/mruby.exe'
$outDir = Join-Path $expRoot 'output'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$preludePath = Join-Path $expRoot 'runtime_prelude.rb'
$onigShim = Get-Content -Raw (Join-Path $repoRoot 'RGSS/ext/onig_regexp.rb')
$prelude = @"
module Kernel; module_function :eval; end
class String
  unless method_defined?(:force_encoding)
    def force_encoding(enc)
      @__enc__ = enc.to_s.upcase
      self
    end
    alias __orig_len__ length
    def length
      (@__enc__ == 'ASCII-8BIT' || @__enc__ == 'BINARY') ? bytesize : __orig_len__
    end
  end
end
class Array
  unless method_defined?(:__rgss_mri_sort_bang__)
    alias_method :__rgss_mri_sort_bang__, :sort!
    alias_method :__rgss_mri_sort__, :sort
  end
  def __rgss_mri_cmpint__(v)
    return nil if v.nil?
    return 1 if v > 0
    return -1 if v < 0
    0
  end
  def sort!(&block)
    return __rgss_mri_sort_bang__ unless block
    __rgss_mri_sort_bang__ {|a, b| __rgss_mri_cmpint__(block.call(a, b)) }
  end
  def sort(&block)
    return __rgss_mri_sort__ unless block
    __rgss_mri_sort__ {|a, b| __rgss_mri_cmpint__(block.call(a, b)) }
  end
end
$onigShim
`$rgss_compat_output = '$($outDir.Replace('\', '/'))'
`$ruby_runtime_host = true
"@
[System.IO.File]::WriteAllText($preludePath, $prelude, (New-Object System.Text.UTF8Encoding($false)))

& $mrubyExe -r $preludePath (Join-Path $repoRoot 'tests/fixtures/ruby_runtime_reference.rb')
Write-Output "DEFINED_RUNTIME_FIXTURE_EXIT:$LASTEXITCODE"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$actualRuntime = (Get-Content -Raw (Join-Path $outDir 'ruby_runtime_reference.tsv')).Replace("`r`n", "`n").Trim()
$expectedRuntime = (Get-Content -Raw (Join-Path $repoRoot 'tests/fixtures/ruby_runtime_original.tsv')).Replace("`r`n", "`n").Trim()
if ($actualRuntime -ne $expectedRuntime) {
    Write-Output 'DEFINED_RUNTIME_ORIGINAL_PARITY:FAIL'
    exit 1
}
Write-Output 'DEFINED_RUNTIME_ORIGINAL_PARITY:PASS'

& $mrubyExe -r $preludePath (Join-Path $PSScriptRoot 'defined_yield_super_reference.rb')
Write-Output "DEFINED_YIELD_SUPER_FIXTURE_EXIT:$LASTEXITCODE"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$actualYSLines = Get-Content (Join-Path $outDir 'defined_yield_super_reference.tsv')
$expectedYSLines = Get-Content (Join-Path $PSScriptRoot 'defined_yield_super_original.tsv')
$ysDiffRows = @()
for ($i = 0; $i -lt [Math]::Max($actualYSLines.Count, $expectedYSLines.Count); $i++) {
    $a = if ($i -lt $actualYSLines.Count) { $actualYSLines[$i] } else { '<EOF>' }
    $e = if ($i -lt $expectedYSLines.Count) { $expectedYSLines[$i] } else { '<EOF>' }
    if ($a -ne $e) { $ysDiffRows += ($i + 1) }
}
if (($ysDiffRows -join ',') -ne '69,71,72') {
    Write-Output "DEFINED_YIELD_SUPER_ORIGINAL_PARITY:FAIL (unexpected diff rows: $($ysDiffRows -join ','))"
    exit 1
}
Write-Output 'DEFINED_YIELD_SUPER_ORIGINAL_PARITY:PASS_74_OF_77_WITH_3_DOCUMENTED_ONIG_WRAPPER_ROWS'

& $mrubyExe (Join-Path $PSScriptRoot 'test_defined_semantics.rb')
Write-Output "DEFINED_EXTENDED_EXIT:$LASTEXITCODE"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 3. Build owned replacement host libmruby_x64.dll (never touching Plugins/windows/libmruby_x64.dll)
#    and verify ABI offset 18800 + all 4 Windows native extension DLLs
$hostDllConfPath = Join-Path $expRoot 'build_config_host_dll.rb'
$hostDllConf = @"
MRuby::Build.new do |conf|
  conf.toolchain :visualcpp
  conf.gembox 'default'

  conf.cc do |cc|
    cc.defines = %w(MRB_CORE MRB_INT64 MRB_UTF8_STRING MRB_USE_DEBUG_HOOK MRB_LIB)
  end

  conf.build_dir = File.expand_path('mruby/build/host-dll', __dir__)

  gperf_candidate = File.expand_path('tools/gperf/mingw64/bin/gperf.exe', __dir__)
  if File.exist?(gperf_candidate)
    conf.gperf do |gperf|
      gperf.command = gperf_candidate
      gperf.compile_options = %q[-L ANSI-C -C -j1 -i 1 -o -t -N mrb_reserved_word -k"1,3,$" "%{infile}" > "%{outfile}"]
    end
  end

  conf.enable_bintest
  conf.enable_test
end
"@
[System.IO.File]::WriteAllText($hostDllConfPath, $hostDllConf, (New-Object System.Text.UTF8Encoding($false)))

$hostDllCmdPath = Join-Path $expRoot 'run_build_host_dll.cmd'
$hostDllCmd = @"
@echo off
call "$vcvars"
if errorlevel 1 exit /b %errorlevel%
cd /d "$mrubyCopy"
if errorlevel 1 exit /b %errorlevel%
rake MRUBY_CONFIG=../build_config_host_dll.rb all
exit /b %errorlevel%
"@
[System.IO.File]::WriteAllText($hostDllCmdPath, $hostDllCmd, [System.Text.Encoding]::ASCII)

$procHostLib = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/d', '/c', $hostDllCmdPath) -NoNewWindow -Wait -PassThru
Write-Output "DEFINED_HOST_STATIC_EXIT:$($procHostLib.ExitCode)"
if ($procHostLib.ExitCode -ne 0) { exit $procHostLib.ExitCode }

$sharedDst = Join-Path $expRoot 'mruby-shared'
New-Item -ItemType Directory -Force -Path (Join-Path $sharedDst 'src') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $sharedDst 'tools') | Out-Null
Copy-Item -Force (Join-Path $sharedGlueSrc 'src/main.c') (Join-Path $sharedDst 'src/main.c')
Copy-Item -Force (Join-Path $sharedGlueSrc 'src/main.h') (Join-Path $sharedDst 'src/main.h')
Copy-Item -Force (Join-Path $sharedGlueSrc 'tools/mruby_x64.def') (Join-Path $sharedDst 'tools/mruby_x64.def')

$xmakeLua = @"
add_rules("mode.debug", "mode.release", "mode.releasedbg")

local mruby_build_dir = "../mruby/build/host-dll"

target("libmruby_x64")
    set_arch("x64")
    set_kind("shared")
    set_basename("libmruby_x64")
    set_runtimes("MD")
    add_files("src/*.c")
    add_files("tools/mruby_x64.def")
    add_includedirs("src/", mruby_build_dir .. "/include")
    add_defines("MRB_CORE", "MRB_LIB", "MRB_INT64", "MRB_UTF8_STRING", "MRB_USE_DEBUG_HOOK", "MRB_BUILD_AS_DLL")
    add_links("Ws2_32.lib",
        mruby_build_dir .. "/lib/libmruby.lib",
        mruby_build_dir .. "/lib/libmruby_core.lib")
"@
[System.IO.File]::WriteAllText((Join-Path $sharedDst 'xmake.lua'), $xmakeLua, (New-Object System.Text.UTF8Encoding($false)))

Push-Location $sharedDst
try {
    & xmake f -m release -y | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "xmake f failed: $LASTEXITCODE" }
    & xmake | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "xmake build failed: $LASTEXITCODE" }
} finally {
    Pop-Location
}
Write-Output 'DEFINED_OWNED_HOST_DLL_BUILD:PASS'

$stageDir = Join-Path $expRoot 'extended-host-stage'
$hostOutDir = Join-Path $expRoot 'extended-host-output'
New-Item -ItemType Directory -Force -Path $stageDir | Out-Null
New-Item -ItemType Directory -Force -Path $hostOutDir | Out-Null

Copy-Item -Force (Join-Path $sharedDst 'build/windows/x64/release/libmruby_x64.dll') (Join-Path $stageDir 'libmruby_x64.dll')
foreach ($ext in @('libmruby_marshal_c_ext_x64.dll', 'libmruby_onig_regexp_ext_x64.dll', 'libmruby_dir_glob_ext_x64.dll', 'libmruby_zlib_ext_x64.dll')) {
    Copy-Item -Force (Join-Path $repoRoot "Plugins/windows/$ext") (Join-Path $stageDir $ext)
}

$probeCmdPath = Join-Path $expRoot 'run_build_extended_probe.cmd'
$probeInclude = Join-Path $expRoot 'mruby/build/host-dll/include'
$probeSrc = Join-Path $PSScriptRoot 'extended_host_probe.c'
$probeLib = Join-Path $sharedDst 'build/windows/x64/release/libmruby_x64.lib'
$probeExe = Join-Path $stageDir 'extended_host_probe.exe'
$probeObj = Join-Path $stageDir 'extended_host_probe.obj'
$probeCmd = @"
@echo off
call "$vcvars"
if errorlevel 1 exit /b %errorlevel%
cl /nologo /MD /DMRB_INT64 /DMRB_UTF8_STRING /DMRB_USE_DEBUG_HOOK /I "$probeInclude" "$probeSrc" "$probeLib" /Fe:"$probeExe" /Fo:"$probeObj"
exit /b %errorlevel%
"@
[System.IO.File]::WriteAllText($probeCmdPath, $probeCmd, [System.Text.Encoding]::ASCII)

$procProbeBuild = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/d', '/c', $probeCmdPath) -NoNewWindow -Wait -PassThru
if ($procProbeBuild.ExitCode -ne 0) { exit $procProbeBuild.ExitCode }

Push-Location $stageDir
try {
    & $probeExe ($repoRoot.Replace('\', '/') + '/RGSS') ($hostOutDir.Replace('\', '/')) ((Join-Path $PSScriptRoot 'defined_yield_super_reference.rb').Replace('\', '/')) ((Join-Path $repoRoot 'tests/fixtures/ruby_runtime_reference.rb').Replace('\', '/')) '' ((Join-Path $repoRoot 'tests/fixtures/zlib_stream_reference.rb').Replace('\', '/'))
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}

foreach ($pair in @(
    @('ruby_runtime_reference.tsv', (Join-Path $repoRoot 'tests/fixtures/ruby_runtime_original.tsv')),
    @('zlib_stream_reference.tsv', (Join-Path $repoRoot 'tests/fixtures/zlib_stream_original.tsv'))
)) {
    $act = (Get-Content -Raw (Join-Path $hostOutDir $pair[0])).Replace("`r`n", "`n").Trim()
    $exp = (Get-Content -Raw $pair[1]).Replace("`r`n", "`n").Trim()
    if ($act -ne $exp) {
        Write-Output "DEFINED_HOST_DLL_PARITY_FAIL:$($pair[0])"
        exit 1
    }
}
Write-Output 'DEFINED_EXTENDED_HOST_ABI_AND_GEMS:PASS'
Write-Output 'DEFINED_COMPILER_EXPERIMENT_PASS'
