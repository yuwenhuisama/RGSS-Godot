module CModSuper
  def mod_only_m; defined?(super($side += 1)); end
  def mod_backed_m; defined?(super($side += 1)); end
  def mod_backed_closure; proc { defined?(super($side += 1)) }; end
end

class CBaseProbe
  def inherited_pub(x = 0); x; end
  def mod_backed_m; :base; end
  def mod_backed_closure; :base_mod_c; end
  def orig_m; :orig; end
  def closure_sup_m; :base_closure; end
  protected def inherited_prot; end
  private def inherited_priv; end
end

class CProbe < CBaseProbe
  include CModSuper
  @@cv_defined = 10
  CONST_VAL = 1
  CONST_NIL = nil
  CONST_FALSE = false
  attr_accessor :prop
  def pub_m; end
  protected def prot_m; end
  private def priv_m; end
  def inside
    [
      defined?(pub_m),
      defined?(prot_m),
      defined?(priv_m),
      defined?(self.pub_m),
      defined?(self.prot_m),
      defined?(self.priv_m),
      defined?(@@cv_defined),
      defined?(@@cv_missing),
      defined?(yield($side += 1)),
      defined?(super($side += 1)),
    ]
  end
  def inherited_pub
    [defined?(super), defined?(super($side += 1)), [1].map { defined?(super($side += 10)) }[0]]
  end
  def inherited_prot; defined?(super); end
  def inherited_priv; defined?(super); end
  def orig_m; defined?(super); end
  alias renamed_orig_m orig_m
  define_method(:inherited_pub_dm) { defined?(super) }
  define_method(:dyn_backed_m) { defined?(super($side += 1)) }
  def closure_sup_m; proc { defined?(super($side += 1)) }; end
  def closure_sup_missing; proc { defined?(super($side += 1)) }; end
  def yield_check
    [defined?(yield), defined?(yield($side += 1)), [1].map { defined?(yield($side += 10)) }[0]]
  end
  def yield_escaped
    proc { defined?(yield($side += 100)) }
  end
  define_method(:dm_yield) { defined?(yield($side += 1)) }
  def install_dm_in_def
    self.class.send(:define_method, :dm_in_def_yield) { defined?(yield($side += 1)) }
  end
end

class CBaseProbe
  def dyn_backed_m; :base_dyn; end
end

class CAliasSub < CBaseProbe
  def sub_only_m; defined?(super); end
  alias orig_m sub_only_m
end

class CUnrelated; end
class CModOnlyNoBase; include CModSuper; end
class CSiblingNoMod < CBaseProbe; end

class DynResp
  def respond_to_missing?(sym, include_priv = false)
    sym == :ghost_ok
  end
end

$side = 0
def bump_recv
  $side += 1
  CProbe
end
def raise_recv
  raise "boom"
end

obj = CProbe.new
obj.instance_variable_set(:@iv_set, nil)
alias_sub = CAliasSub.new
dyn = DynResp.new
local_x = 42

single_obj = CProbe.new
def single_obj.inherited_pub; defined?(super($side += 1)); end
def single_obj.single_only_m; defined?(super($side += 1)); end

checks = [
  ['const_present', defined?(Object), 'constant'],
  ['const_top_colon3', defined?(::Object), 'constant'],
  ['const_scoped', defined?(CProbe::CONST_VAL), 'constant'],
  ['const_nil_val', defined?(CProbe::CONST_NIL), 'constant'],
  ['const_false_val', defined?(CProbe::CONST_FALSE), 'constant'],
  ['const_scoped_missing', defined?(CProbe::NO_SUCH), nil],
  ['const_missing_outer', defined?(NoSuchOuter::CONST_VAL), nil],
  ['const_non_module_base', defined?(123::CONST_VAL), nil],
  ['const_raise_base', defined?(raise_recv::CONST_VAL), nil],
  ['const_recv_eval_once', [defined?(bump_recv::CONST_VAL), $side], ['constant', 1]],
  ['method_fcall_priv', defined?(puts), 'method'],
  ['method_fcall_missing', defined?(no_such_method_xyz), nil],
  ['method_call_pub', defined?(obj.pub_m), 'method'],
  ['method_call_prot_ext', defined?(obj.prot_m), nil],
  ['method_call_priv_ext', defined?(obj.priv_m), nil],
  ['method_inside_vis', begin $side = 0; [obj.inside, $side] end, [['method', 'method', 'method', 'method', 'method', nil, 'class variable', nil, nil, nil], 0]],
  ['method_args_uneval', begin $side = 0; [defined?(puts($side += 1)), $side] end, ['method', 0]],
  ['method_recv_raise', defined?(raise_recv.pub_m), nil],
  ['method_respond_to_missing_t', defined?(dyn.ghost_ok), 'method'],
  ['method_respond_to_missing_f', defined?(dyn.ghost_no), nil],
  ['method_safe_nav_nil', begin n = nil; defined?(n&.no_such_method) end, nil],
  ['gvar_present', defined?($side), 'global-variable'],
  ['gvar_nil_present', begin $g_nil = nil; defined?($g_nil) end, 'global-variable'],
  ['gvar_missing', defined?($no_such_global_xyz), nil],
  ['ivar_nil_present', obj.instance_eval { defined?(@iv_set) }, 'instance-variable'],
  ['ivar_missing', obj.instance_eval { defined?(@iv_missing) }, nil],
  ['lvar_present', defined?(local_x), 'local-variable'],
  ['asgn_lvar_uneval', begin $side = 0; [defined?(new_lv = ($side += 1)), $side, new_lv] end, ['assignment', 0, nil]],
  ['op_asgn_uneval', begin $side = 0; [defined?($side += 1), $side] end, ['assignment', 0]],
  ['masgn_paren_uneval', begin $side = 0; [defined?((ma, mb = ($side += 1))), $side] end, ['assignment', 0]],
  ['attr_asgn_def_uneval', begin $side = 0; [defined?(obj.prop = ($side += 1)), $side] end, ['method', 0]],
  ['attr_asgn_undef_uneval', begin $side = 0; [defined?(obj.no_setter = ($side += 1)), $side] end, [nil, 0]],
  ['aref_asgn_def_uneval', begin h = {}; $side = 0; [defined?(h[$side += 1] = ($side += 10)), $side] end, ['method', 0]],
  ['aref_asgn_undef_uneval', begin $side = 0; [defined?(obj[0] = ($side += 1)), $side] end, [nil, 0]],
  ['self_kw', defined?(self), 'self'],
  ['nil_kw', defined?(nil), 'nil'],
  ['true_kw', defined?(true), 'true'],
  ['false_kw', defined?(false), 'false'],
  ['nested_defined', defined?(defined?(NoSuchConst)), 'expression'],
  ['literal_int', defined?(123), 'expression'],
  ['unparen_const', (defined? Object), 'constant'],
  ['unparen_asgn', begin $side = 0; [(defined? $side += 1), $side] end, ['assignment', 0]],
  ['unparen_ternary', (defined? Object ? 1 : 2), 'expression'],
  ['def_method_named_defined', eval('class CDefName; def defined?; 77; end; end; [CDefName.new.defined?, :defined?]'), [77, :defined?]],
  ['yield_toplevel_uneval', begin $side = 0; [defined?(yield($side += 1)), $side] end, [nil, 0]],
  ['yield_absent_uneval', begin $side = 0; [obj.yield_check, $side] end, [[nil, nil, nil], 0]],
  ['yield_present_uneval', begin $side = 0; [obj.yield_check { $side += 999 }, $side] end, [['yield', 'yield', 'yield'], 0]],
  ['yield_escaped_closure', begin $side = 0; [obj.yield_escaped.call, (obj.yield_escaped { $side += 999 }).call, $side] end, [nil, 'yield', 0]],
  ['yield_define_method_class', begin $side = 0; [obj.dm_yield, (obj.dm_yield { $side += 999 }), $side] end, [nil, nil, 0]],
  ['yield_define_method_in_def', begin $side = 0; obj.install_dm_in_def; r1 = (obj.dm_in_def_yield { 1 }); obj.install_dm_in_def { :outer }; r2 = obj.dm_in_def_yield; [r1, r2, $side] end, [nil, 'yield', 0]],
  ['super_toplevel_uneval', begin $side = 0; [defined?(super($side += 1)), $side] end, [nil, 0]],
  ['super_present_uneval', begin $side = 0; [obj.inherited_pub, $side] end, [['super', 'super', 'super'], 0]],
  ['super_vis_priv_prot', [obj.send(:inherited_prot), obj.send(:inherited_priv)], ['super', 'super']],
  ['super_module_present_missing', begin $side = 0; [obj.mod_backed_m, obj.mod_only_m, $side] end, ['super', nil, 0]],
  ['super_singleton_present_missing', begin $side = 0; [single_obj.inherited_pub, single_obj.single_only_m, $side] end, ['super', nil, 0]],
  ['super_alias_lexical', [alias_sub.orig_m, obj.renamed_orig_m], [nil, 'super']],
  ['super_define_method', begin $side = 0; [obj.dyn_backed_m, obj.inherited_pub_dm, $side] end, ['super', nil, 0]],
  ['super_escaped_closure', begin $side = 0; [obj.closure_sup_m.call, obj.closure_sup_missing.call, $side] end, ['super', nil, 0]],
  ['ary_empty_and_literals', [defined?([]), defined?([1, :a, 'b', nil, false])], ['expression', 'expression']],
  ['ary_recursive_missing_uneval', begin $side = 0; [defined?([Object, NoSuchAryConst]), defined?([NoSuchAryConst, ($side += 1)]), defined?([[Object], [1, [NoSuchAryConst]]]), $side] end, [nil, nil, nil, 0]],
  ['ary_short_circuit_recv', begin $side = 0; r1 = defined?([NoSuchAryConst, bump_recv::CONST_VAL]); c1 = $side; $side = 0; r2 = defined?([bump_recv::CONST_VAL, NoSuchAryConst, bump_recv::CONST_VAL]); c2 = $side; [r1, c1, r2, c2] end, [nil, 0, nil, 1]],
  ['ary_splat_short_circuit', begin $side = 0; [defined?([*NoSuchAryConst, NoSuchAryConst2]), defined?(%W[a #{$side += 1}]), $side] end, ['expression', 'expression', 0]],
  ['super_iexec_class_rebound', begin $side = 0; p_ok = obj.closure_sup_m; p_no = obj.closure_sup_missing; [CUnrelated.new.instance_exec(&p_ok), 123.instance_exec(&p_ok), CUnrelated.new.instance_exec(&p_no), $side] end, ['super', 'super', nil, 0]],
  ['super_iexec_module_rebound', begin $side = 0; pm = obj.mod_backed_closure; [obj.instance_exec(&pm), CModOnlyNoBase.new.instance_exec(&pm), CSiblingNoMod.new.instance_exec(&pm), CUnrelated.new.instance_exec(&pm), $side] end, ['super', nil, nil, nil, 0]],
  ['match_tilde_always_defined', [defined?($~), $~, defined?($&), defined?($+), defined?($1), defined?($10)], ['global-variable', nil, nil, nil, nil, nil]],
]

failures = []
checks.each do |label, actual, expected|
  if actual != expected
    failures << "#{label}: expected #{expected.inspect}, got #{actual.inspect}"
  end
end

if failures.empty?
  puts "DEFINED_SEMANTICS_PASS:#{checks.size}"
else
  failures.each { |f| puts "DEFINED_SEMANTICS_FAIL:#{f}" }
  exit 1
end
