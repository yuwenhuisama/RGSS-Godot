# Object


全てのクラスのスーパークラス。 オブジェクトの一般的な振舞いを定義します。

## インクルードしているモジュール


- [Kernel](sm_kernel.md)


## メソッド



### *self* == *other*



self と *other* が等しいかどうか判定します。 デフォルトでは equal? と同じ効果です。

このメソッドは各クラスの性質に合わせて再定義するべきです。

### *self* === *other*



このメソッドは [case](syntax05.md#L000301) 文での比較に用いられます。デフォルトは [Object#==](#L000555) と同じ働きをしますが、 この挙動はサブクラスで所属性のチェックを実現するため 適宜再定義されます。

### class



レシーバのクラスを返します。

### clone


### dup



オブジェクトの複製を作ります。 clone は freeze、特異メソッドなどの情報も含めた完全な複製を、dup は オブジェクトの内容のみの複製を作ります。

clone や dup は「浅い (shallow)」コピーであることに注意 してください。オブジェクト自身を複製するだけで、オブジェクトの指し ている先 (たとえば配列の要素など) までは複製しません。

また複製したオブジェクトに対して

```

obj.equal?(obj.clone)
```



は一般に成立しませんが、

```

obj == obj.clone
```



は多くの場合に成立します。

true、false、nil、[Numeric](sc_numeric.md) オブジェクト、[Symbol](sc_symbol.md) オブジェクトなどを複製しようとすると例外 [TypeError](s_exceptions.md#TypeError) が発生します。

### equal?(*other*)



other が self 自身のとき、真を返します。 このメソッドを再定義してはいけません。

### freeze



オブジェクトの内容の変更を禁止します。 フリーズされたオブジェクトの変更は例外 [TypeError](s_exceptions.md#TypeError) を発生させます。

### frozen?



オブジェクトの内容の変更が禁止されているときに真を返します。

### inspect



オブジェクトを人間が読める形式の文字列に変換します。

### instance_of?(*klass*)



self がクラス *klass* の直接のインスタンスであるとき、 真を返します。obj.instance_of?(c) が成立するときには、常に obj.kind_of?(c) も成立します。

### instance_variable_get(*var*)



オブジェクトのインスタンス変数の値を取得して返します。

*var* にはインスタンス変数名を文字列か [Symbol](sc_symbol.md) で指定しま す。

インスタンス変数が定義されていなければ nil を返します。

```

class Foo
 def initialize
 @foo = 1
 end
end

obj = Foo.new
p obj.instance_variable_get("@foo") # => 1
p obj.instance_variable_get(:@foo) # => 1
p obj.instance_variable_get(:@bar) # => nil
```



### instance_variable_set(*var*, *val*)



オブジェクトのインスタンス変数に値 *val* を設定して *val* を返します。

*var* にはインスタンス変数名を文字列か [Symbol](sc_symbol.md) で指定しま す。

インスタンス変数が定義されていなければ新たに定義されます。

```

obj = Object.new
p obj.instance_variable_set("@foo", 1) # => 1
p obj.instance_variable_set(:@foo, 2) # => 2
p obj.instance_variable_get(:@foo) # => 2
```



### instance_variables



オブジェクトのインスタンス変数名を文字列の配列として返します。

```

obj = Object.new
obj.instance_eval { @foo, @bar = nil }
p obj.instance_variables

# => ["@foo", "@bar"]
```



### is_a?(*mod*)


### kind_of?(*mod*)



self が、クラス *mod* とそのサブクラス、および モジュール *mod* をインクルードしたクラスとそのサブクラス、 のいずれかのインスタンスであるとき真を返します。

```

module M
end
class C < Object
 include M
end
class S < C
end

obj = S.new
p obj.is_a? S # true
p obj.is_a? M # true
p obj.is_a? C # true
p obj.is_a? Object # true
p obj.is_a? Hash # false
```



### method(*name*)



self のメソッド *name* をオブジェクト化した [Method](sc_method.md) オブジェクトを返します。*name* は [Symbol](sc_symbol.md) または文字列で指定します。

### nil?



レシーバが nil であれば真を返します。

### respond_to?(*name*[, *priv*=*false*])



オブジェクトが public メソッド *name* を持つとき真を返します。

*name* は [Symbol](sc_symbol.md) または文字列です。*priv* が真のとき は private メソッドに対しても真を返します。

### send(*name*[, *args* ... ])


### send(*name*[, *args* ... ]) { .... }`



オブジェクトのメソッド *name* を、引数に *args* を渡して呼び出し、メソッドの実行結果を返します。

ブロック付きで呼ばれたときはブロックもそのまま引き渡します。メソッド名 *name* は文字列か [Symbol](sc_symbol.md) です。

### object_id



各オブジェクトに対して一意な整数を返します。あるオブジェクトに対し てどのような整数が割り当てられるかは不定です。

### to_ary



オブジェクトの配列への暗黙の変換が必要なときに内部で呼ばれます。

### to_hash



オブジェクトのハッシュへの暗黙の変換が必要なときに内部で呼ばれます。

### to_int



オブジェクトの整数への暗黙の変換が必要なときに内部で呼ばれます。

### to_s



オブジェクトの文字列表現を返します。

[print](s_functions.md#print) や [sprintf](s_functions.md#sprintf) は文字列以外の オブジェクトが引数に渡された場合このメソッドを使って文字列に変換し ます。

### to_str



オブジェクトの文字列への暗黙の変換が必要なときに呼ばれます。

## プライベートメソッド



### initialize



ユーザー定義クラスのオブジェクト初期化メソッド。このメソッドは [Class#new](sc_class.md#L001138) から新しく生成されたオブジェクトの 初期化のために呼び出されます。デフォルトの動作ではなにもしません。 サブクラスではこのメソッドを必要に応じて再定義されることが期待されていま す。initialize には [Class#new](sc_class.md#L001138) に 与えられた引数がそのまま渡されます。

######
