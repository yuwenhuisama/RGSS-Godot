# Symbol


シンボルを表すクラス。[シンボル](syntax03.md#L000282)を 参照してください。

## スーパークラス


- [Object](sc_object.md)


## メソッド



### id2name


シンボルに対応する文字列を返します。

文字列に対応するシンボルを得るには [String#to_sym](sc_string.md#L001398) を使います。

```

p :foo.id2name.to_sym == :foo # => true
```



### to_i



シンボルに対応する整数を返します。

この整数から対応するシンボルを得るには [Fixnum#to_sym](sc_fixnum.md#L001220) を使います。

```

p :foo.to_i # => 8881
p :foo.to_i.to_sym # => :foo
```



Ruby の実装では予約語、変数名、メソッド名などをこの整数で管理してい ます。オブジェクトに対応する整数 ([Object#object_id](sc_object.md#L000571) で得ら れます) と Symbol に対応する整数は別のものです。

######
