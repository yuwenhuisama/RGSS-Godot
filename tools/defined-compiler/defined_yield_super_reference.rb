# Shared RGSS300 + mruby reference fixture for unevaluated defined?(yield), defined?(super),
# array literal recursive definedness, escaped super closures via instance_exec, and OnigRegexp match globals.
# Executed unmodified on both original RGSS300 (Game.exe) and native mruby.

output = $rgss_compat_output || '.'
$defined_ys_side_effects = 0
$defined_ary_recv_evals = 0

def defined_ary_recv_ok
  $defined_ary_recv_evals += 1
  Object
end

module DefinedSuperModuleOnly
  def mod_only_zsuper
    defined?(super)
  end

  def mod_only_super_args
    defined?(super($defined_ys_side_effects += 1))
  end

  def mod_only_closure
    proc { defined?(super($defined_ys_side_effects += 1)) }
  end
end

module DefinedSuperModuleWithBase
  def mod_backed_zsuper
    defined?(super)
  end

  def mod_backed_super_args
    defined?(super($defined_ys_side_effects += 1))
  end

  def mod_backed_closure
    proc { defined?(super($defined_ys_side_effects += 1)) }
  end
end

class DefinedSuperBase
  def pub_method(x = 0)
    x
  end

  def mod_backed_zsuper
    :base_zsuper
  end

  def mod_backed_super_args(x = 0)
    x
  end

  def mod_backed_closure
    :base_mod_closure
  end

  def orig_target
    :base_orig
  end

  def eval_backed
    :base_eval
  end

  def dyn_backed
    :base_dyn
  end

  def closure_backed
    :base_closure
  end

  private
  def priv_method
    :priv
  end

  protected
  def prot_method
    :prot
  end
end

class DefinedSuperChild < DefinedSuperBase
  include DefinedSuperModuleOnly
  include DefinedSuperModuleWithBase

  def pub_method(x = 0)
    [
      defined?(super),
      defined?(super($defined_ys_side_effects += 1, RGSSMissingSuperArgConst)),
      [1].map { defined?(super($defined_ys_side_effects += 10)) }[0]
    ].join(',')
  end

  def missing_method
    [
      defined?(super),
      defined?(super($defined_ys_side_effects += 100, RGSSMissingSuperArgConst)),
      [1].map { defined?(super($defined_ys_side_effects += 1000)) }[0]
    ].map { |v| v.nil? ? 'nil' : v }.join(',')
  end

  def priv_method
    defined?(super)
  end

  def prot_method
    defined?(super)
  end

  def orig_target
    defined?(super)
  end
  alias renamed_orig_target orig_target

  define_method(:dyn_backed) { defined?(super($defined_ys_side_effects += 1)) }
  define_method(:dyn_missing) { defined?(super($defined_ys_side_effects += 1)) }
  define_method(:dyn_backed_closure) { proc { defined?(super($defined_ys_side_effects += 1)) } }
  define_method(:dyn_missing_closure) { proc { defined?(super($defined_ys_side_effects += 1)) } }

  def eval_backed
    eval('defined?(super($defined_ys_side_effects += 1))')
  end

  def eval_missing
    eval('defined?(super($defined_ys_side_effects += 1))')
  end

  def closure_backed
    proc { defined?(super($defined_ys_side_effects += 1)) }
  end

  def missing_closure_method
    proc { defined?(super($defined_ys_side_effects += 1)) }
  end
end

class DefinedSuperGrandChild < DefinedSuperChild
end

class DefinedSuperSiblingNoMod < DefinedSuperBase
end

class DefinedSuperOtherModChild < DefinedSuperBase
  include DefinedSuperModuleWithBase
end

class DefinedSuperModWithoutBase
  include DefinedSuperModuleWithBase
end

class DefinedSuperAliasSub < DefinedSuperBase
  def sub_only_name
    defined?(super)
  end
  alias orig_target sub_only_name
end

class DefinedSuperUnrelated
end

class DefinedYieldProbe
  def direct_yield
    [
      defined?(yield),
      defined?(yield($defined_ys_side_effects += 1, RGSSMissingYieldArgConst)),
      [1].map { defined?(yield($defined_ys_side_effects += 10)) }[0]
    ].map { |v| v.nil? ? 'nil' : v }.join(',')
  end

  def escaped_closure_yield
    proc { defined?(yield($defined_ys_side_effects += 100)) }
  end

  def eval_yield
    eval('defined?(yield($defined_ys_side_effects += 1000))')
  end

  define_method(:dm_class_yield) { defined?(yield($defined_ys_side_effects += 1)) }
  define_method(:dm_class_eval_yield) { eval('defined?(yield($defined_ys_side_effects += 1))') }

  def install_dm_from_method
    self.class.send(:define_method, :dm_method_yield) do
      defined?(yield($defined_ys_side_effects += 1))
    end
  end
end

class DefinedMatchScopeProbe
  def inner_match
    /(in1)(in2)/.match('in1in2')
    [defined?($1), $1, defined?($2), $2]
  end

  def outer_match
    /(out1)(out2)/.match('out1out2')
    blk_before = [1].map { [defined?($1), $1] }[0]
    sub_res = inner_match
    blk_after = [1].map { [defined?($1), $1, defined?($2), $2] }[0]
    eval_res = eval('/(ev1)(ev2)/.match("ev1ev2"); [defined?($1), $1]')
    after_eval = [defined?($1), $1, defined?($2), $2]
    [blk_before, sub_res, blk_after, eval_res, after_eval]
  end

  define_method(:dm_isolated_match) do
    /(dm1)(dm2)/.match('dm1dm2')
    [defined?($1), $1]
  end

  def caller_around_dm
    /(cm1)(cm2)/.match('cm1cm2')
    dm_res = dm_isolated_match
    [dm_res, defined?($1), $1, defined?($2), $2]
  end

  def make_shared_closures
    /(sh1)(sh2)/.match('sh1sh2')
    reader = proc { [defined?($1), $1, defined?($2), $2] }
    writer = proc { /(up1)(up2)/.match('up1up2') }
    [reader, writer]
  end
end

$defined_super_in_class_body = nil
class DefinedScopeBodyProbe
  $defined_super_in_class_body = defined?(super($defined_ys_side_effects += 1))
end

$defined_super_in_module_body = nil
module DefinedModuleBodyProbe
  $defined_super_in_module_body = defined?(super($defined_ys_side_effects += 1))
end

# Capture match-global initial state BEFORE any regex operation runs in this VM
$match_init_snapshot = [
  defined?($~),
  $~,
  defined?($&),
  defined?($`),
  defined?($'),
  defined?($+),
  defined?($1),
  defined?($2),
  defined?($10)
]

yp = DefinedYieldProbe.new
sc = DefinedSuperChild.new
sa = DefinedSuperAliasSub.new
ms = DefinedMatchScopeProbe.new

singleton_obj = DefinedSuperChild.new
def singleton_obj.pub_method
  defined?(super($defined_ys_side_effects += 1))
end
def singleton_obj.singleton_only_method
  defined?(super($defined_ys_side_effects += 1))
end
def singleton_obj.closure_backed
  proc { defined?(super($defined_ys_side_effects += 1)) }
end
def singleton_obj.singleton_only_closure
  proc { defined?(super($defined_ys_side_effects += 1)) }
end

File.open(File.join(output, 'defined_yield_super_reference.tsv'), 'w') do |file|
  emit = lambda do |label, value|
    file.puts [label, value.nil? ? 'nil' : value.to_s].join("\t")
  end

  # --- Milestone-2 Core 35 Rows ---
  emit.call('yield-toplevel', defined?(yield($defined_ys_side_effects += 1)))
  emit.call('yield-toplevel-eval', eval('defined?(yield($defined_ys_side_effects += 1))'))
  emit.call('yield-method-no-block', yp.direct_yield)
  emit.call('yield-method-with-block', yp.direct_yield { $defined_ys_side_effects += 10000 })
  emit.call('yield-escaped-closure-no-block', yp.escaped_closure_yield.call)
  emit.call('yield-escaped-closure-with-block', (yp.escaped_closure_yield { $defined_ys_side_effects += 10000 }).call)
  emit.call('yield-eval-no-block', yp.eval_yield)
  emit.call('yield-eval-with-block', yp.eval_yield { $defined_ys_side_effects += 10000 })
  emit.call('yield-define-method-no-block', yp.dm_class_yield)
  emit.call('yield-define-method-with-block', yp.dm_class_yield { $defined_ys_side_effects += 10000 })
  emit.call('yield-define-method-eval-with-block', yp.dm_class_eval_yield { $defined_ys_side_effects += 10000 })

  yp.install_dm_from_method
  emit.call('yield-dm-in-def-outer-absent', yp.dm_method_yield { $defined_ys_side_effects += 10000 })
  yp.install_dm_from_method { :outer_block }
  emit.call('yield-dm-in-def-outer-present', yp.dm_method_yield)

  emit.call('super-toplevel', defined?(super($defined_ys_side_effects += 1)))
  emit.call('super-toplevel-eval', eval('defined?(super($defined_ys_side_effects += 1))'))
  emit.call('super-class-body', $defined_super_in_class_body)
  emit.call('super-module-body', $defined_super_in_module_body)
  emit.call('super-method-present', sc.pub_method)
  emit.call('super-method-missing', sc.missing_method)
  emit.call('super-private-parent', sc.priv_method)
  emit.call('super-protected-parent', sc.prot_method)
  emit.call('super-module-backed-zsuper', sc.mod_backed_zsuper)
  emit.call('super-module-backed-args', sc.mod_backed_super_args)
  emit.call('super-module-only-zsuper', sc.mod_only_zsuper)
  emit.call('super-module-only-args', sc.mod_only_super_args)
  emit.call('super-singleton-present', singleton_obj.pub_method)
  emit.call('super-singleton-missing', singleton_obj.singleton_only_method)
  emit.call('super-alias-lexical-missing', sa.orig_target)
  emit.call('super-alias-lexical-present', sc.renamed_orig_target)
  emit.call('super-define-method-present', sc.dyn_backed)
  emit.call('super-define-method-missing', sc.dyn_missing)
  emit.call('super-eval-present', sc.eval_backed)
  emit.call('super-eval-missing', sc.eval_missing)
  emit.call('super-escaped-closure-present', sc.closure_backed.call)
  emit.call('super-escaped-closure-missing', sc.missing_closure_method.call)

  # --- Edge 1: Array literal recursive definedness with zero side effects ---
  emit.call('ary-empty', defined?([]))
  emit.call('ary-literals', defined?([1, 'a', :s, nil, false, true]))
  emit.call('ary-consts-present', defined?([Object, String, StandardError]))
  emit.call('ary-const-missing-last', defined?([Object, RGSSMissingArrayEdgeConst]))
  emit.call('ary-const-missing-first-uneval', defined?([RGSSMissingArrayEdgeConst, ($defined_ys_side_effects += 1)]))
  emit.call('ary-nested-present', defined?([[Object], [1, [String]]]))
  emit.call('ary-nested-missing', defined?([[Object], [1, [RGSSMissingArrayEdgeConst]]]))
  emit.call('ary-calls-present-uneval', defined?([sc.pub_method($defined_ys_side_effects += 1), yp.direct_yield($defined_ys_side_effects += 10)]))
  emit.call('ary-calls-missing-uneval', defined?([sc.pub_method($defined_ys_side_effects += 1), sc.no_such_ary_edge_method($defined_ys_side_effects += 10)]))
  emit.call('ary-asgn-and-ivar-uneval', defined?([$defined_ys_side_effects += 1, Object]))
  emit.call('ary-ivar-unset-missing', defined?([Object, @rgss_unset_ary_edge_ivar]))
  emit.call('ary-splat-elements', [defined?([*RGSSMissingArrayEdgeConst, Object]), defined?([*no_such_ary_splat_method($defined_ys_side_effects += 1), RGSSMissingArrayEdgeConst])].map { |v| v.nil? ? 'nil' : v }.join(','))
  emit.call('ary-word-literals-uneval', [defined?(%w[a b]), defined?(%W[a #{$defined_ys_side_effects += 1}])].join(','))

  $defined_ary_recv_evals = 0
  r_short1 = defined?([RGSSMissingArrayEdgeConst, defined_ary_recv_ok.to_s])
  c_short1 = $defined_ary_recv_evals
  $defined_ary_recv_evals = 0
  r_short2 = defined?([defined_ary_recv_ok.to_s, RGSSMissingArrayEdgeConst, defined_ary_recv_ok.to_s])
  c_short2 = $defined_ary_recv_evals
  $defined_ary_recv_evals = 0
  r_short3 = defined?([defined_ary_recv_ok.to_s, defined_ary_recv_ok.to_s])
  c_short3 = $defined_ary_recv_evals
  emit.call('ary-short-circuit-order', [r_short1.inspect, c_short1, r_short2.inspect, c_short2, r_short3.inspect, c_short3].join(','))

  # --- Edge 2: Escaped super closure rebound via instance_exec / instance_eval / class_exec ---
  c_cls_ok = sc.closure_backed
  c_cls_no = sc.missing_closure_method
  c_dm_ok = sc.dyn_backed_closure
  c_dm_no = sc.dyn_missing_closure
  c_mod_ok = sc.mod_backed_closure
  c_mod_no = sc.mod_only_closure
  c_sdef_ok = singleton_obj.closure_backed
  c_sdef_no = singleton_obj.singleton_only_closure
  unrel = DefinedSuperUnrelated.new

  emit.call('super-iexec-class-unrelated-present', unrel.instance_exec(&c_cls_ok))
  emit.call('super-iexec-class-unrelated-missing', unrel.instance_exec(&c_cls_no))
  emit.call('super-iexec-class-integer-present', 123.instance_exec(&c_cls_ok))
  emit.call('super-ieval-class-unrelated-present', unrel.instance_eval(&c_cls_ok))
  emit.call('super-cexec-class-unrelated-present', DefinedSuperUnrelated.class_exec(&c_cls_ok))
  emit.call('super-iexec-dm-unrelated-present', unrel.instance_exec(&c_dm_ok))
  emit.call('super-iexec-dm-unrelated-missing', unrel.instance_exec(&c_dm_no))
  emit.call('super-iexec-sdef-unrelated-present', unrel.instance_exec(&c_sdef_ok))
  emit.call('super-iexec-sdef-unrelated-missing', unrel.instance_exec(&c_sdef_no))
  emit.call('super-iexec-mod-self-and-sub', [sc.instance_exec(&c_mod_ok), DefinedSuperGrandChild.new.instance_exec(&c_mod_ok)].join(','))
  emit.call('super-iexec-mod-other-includer-with-base', DefinedSuperOtherModChild.new.instance_exec(&c_mod_ok))
  emit.call('super-iexec-mod-includer-without-base', DefinedSuperModWithoutBase.new.instance_exec(&c_mod_ok))
  emit.call('super-iexec-mod-sibling-without-mod', DefinedSuperSiblingNoMod.new.instance_exec(&c_mod_ok))
  emit.call('super-iexec-mod-unrelated', [unrel.instance_exec(&c_mod_ok), sc.instance_exec(&c_mod_no)].map { |v| v.nil? ? 'nil' : v }.join(','))

  # --- Edge 3: Match globals through actual OnigRegexp wrapper ---
  emit.call('match-init-before-any-regex', $match_init_snapshot.inspect)

  md_opt = /(a)(b)?/.match('xay')
  emit.call('match-opt-tilde-and-regions', [defined?($~), !$~.nil?, defined?($&), $&, defined?($`), $`, defined?($'), $'].inspect)
  emit.call('match-opt-plus-and-groups', [defined?($+), $+, defined?($1), $1, defined?($2), $2, defined?($3), $3, defined?($10), $10].inspect)

  /(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)/.match('abcdefghij')
  emit.call('match-ten-groups', [defined?($9), $9, defined?($10), $10, defined?($11), $11, defined?($+), $+].inspect)

  /(z)/.match('abc')
  emit.call('match-mismatch-clears', [defined?($~), $~, defined?($&), $&, defined?($`), $`, defined?($'), $', defined?($+), $+, defined?($1), $1, defined?($10), $10].inspect)

  'hello-42' =~ /([a-z]+)-(\d+)/
  emit.call('match-str-eqtilde', [defined?($&), $&, defined?($1), $1, defined?($2), $2, defined?($3), $3, defined?($+), $+].inspect)

  'foo1bar2'.sub(/(bar)(\d)/, 'baz')
  emit.call('match-str-sub', [defined?($&), $&, defined?($1), $1, defined?($2), $2, defined?($3)].inspect)

  s_sl = 'pre-789-post'
  sl_ret = s_sl.slice!(/(\d+)/)
  emit.call('match-str-slice-bang', [sl_ret, s_sl, defined?($1), $1, defined?($2)].inspect)

  idx_ret = 'alpha-55'.index(/(\d+)/)
  emit.call('match-str-index', [idx_ret, defined?($1), $1].inspect)

  emit.call('match-method-block-eval-isolation', ms.outer_match.inspect)
  emit.call('match-define-method-isolation', ms.caller_around_dm.inspect)

  rd_proc, wr_proc = ms.make_shared_closures
  /(topA)(topB)/.match('topAtopB')
  before_wr = rd_proc.call
  wr_proc.call
  after_wr = rd_proc.call
  top_unchanged = [defined?($1), $1, defined?($2), $2]
  emit.call('match-escaped-shared-closures', [before_wr, after_wr, top_unchanged].inspect)

  $~ = md_opt
  after_assign_md = [defined?($~), $& , defined?($1), $1, defined?($2), $2, defined?($+), $+]
  $~ = nil
  after_assign_nil = [defined?($~), $~, defined?($&), $&, defined?($1), $1]
  type_err = begin
    $~ = 123
    :no_error
  rescue TypeError
    :type_error
  end
  emit.call('match-explicit-tilde-assign', [after_assign_md, after_assign_nil, type_err].inspect)

  emit.call('defined-ys-side-effect-count', $defined_ys_side_effects)
end
exit unless $ruby_runtime_host
