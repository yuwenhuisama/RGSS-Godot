# Module


モジュールのクラス。

## スーパークラス


- [Object](sc_object.md)


## メソッド



### *self* === *obj*



このメソッドは主に [case](syntax05.md#L000301) 文での比較に用いられます。 *obj* が self と [Object#kind_of?](sc_object.md#L000580) の関係があるとき、真になります。つまり、[case](syntax05.md#L000301) ではクラ ス、モジュールの所属関係をチェックすることになります。

```

str = String.new
case str
when String # String === str を評価する
 p true # => true
end
```



## プライベートメソッド



### attr_accessor(*name* ... )



属性 *name* に対する読み込みメソッドと書き込みメソッドの両方を 定義します。*name* は [Symbol](sc_symbol.md) か文字列で 指定します。

このメソッドで定義されるメソッドの定義は以下の通りです。

```

def name
 @name
end
def name=(val)
 @name = val
end
```



### attr_reader(*name* ... )



属性 *name* の読み込みメソッドを定義します。 *name* は [Symbol](sc_symbol.md) か文字列で指定します。

このメソッドで定義されるメソッドの定義は以下の通りです。

```

def name
 @name
end
```



### attr_writer(*name* ... )



属性 *name* への書き込みメソッド (name=) を定義します。 *name* は [Symbol](sc_symbol.md) か文字列で指定します。

このメソッドで定義されるメソッドの定義は以下の通りです。

```

def name=(val)
 @name = val
end
```



### include(*module* ... )



指定されたモジュールの性質 (メソッドや定数) を追加します。self を返し ます。include は多重継承の代わりに用いられる Mix-in を実現するために 使われます。

```

class C
 include FileTest
 include Math
end
```



モジュールの機能追加は、クラスの継承関係の間にそのモジュールが挿入 されることで実現されています。従って、メソッドの探索などはスーパー クラスに優先されて追加したモジュールから探索されます。

同じモジュールを二回以上 include すると二回目以降は無視されます。 また、モジュールの継承関係が循環してしまうような include を行うと、例外 [ArgumentError](s_exceptions.md#ArgumentError) が発生します。

######
