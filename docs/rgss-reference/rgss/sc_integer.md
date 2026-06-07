# Integer


整数の抽象クラス。サブクラスとして [Fixnum](sc_fixnum.md) と [Bignum](sc_bignum.md) があります。この 2 種類の整数は 値の大きさに応じてお互いに自動的に変換されます。ビット操作において整数は 無限の長さのビットストリングとみなすことができます。

## スーパークラス


- [Numeric](sc_numeric.md)


## メソッド



### self[nth]



*nth* 番目のビット (最下位ビット (LSB) が 0 番目) が立っている とき 1 を、そうでなければ 0 を返します。

self[nth]=bit が Integer にないのは、Numeric 関連クラスが immutable であるためです。

### *self* + *other*


### *self* - *other*


### *self* * *other*


### *self* / *other*


### *self* % *other*


### *self* ** *other*



算術演算子。それぞれ和、差、積、商、剰余、冪を計算します。

### *self* <=> *other*



self と other を比較して、self が 大きいときに正、等しいときに 0、小さいときに負の整数を返します。

### *self* == *other*


### *self* < *other*


### *self* <= *other*


### *self* > *other*


### *self* >= *other*



比較演算子。

### ~ *self*


### *self* | *other*


### *self* & *other*


### *self* ^ *other*



ビット演算子。それぞれ否定、論理和、論理積、排他的論理和を計算しま す。

### *self* << *bits*


### *self* >> *bits*



シフト演算子。bits だけビットを右 (左) にシフトします。

右シフトは、符号ビット (最上位ビット (MSB)) が保持されます。

### chr



文字コードに対応する 1 バイトの文字列を返します。たとえば 65.chr は "A" を返します。

整数は 0 から 255 の範囲内でなければなりません。範囲外の整数に対す る呼び出しは例外 [RangeError](s_exceptions.md#RangeError) を発生させます。

### downto(*min*) {|*n*| ... }



self から *min* まで 1 ずつ減らしながら繰り返します。 self < min であれば何もしません。

[upto](#L001211), [step](#L001203), [times](#L001204) も参照してください。

### next


### succ



*次*の整数を返します。

### step(*limit*, *step*) {|*n*| ... }



self からはじめ *step* を足しながら *limit* を越える 前までブロックを繰り返します。*step* は負の数も指定できます。

*step* に 0 を指定した場合は例外 [ArgumentError](s_exceptions.md#ArgumentError) が発生します。

self を返します。

[upto](#L001211), [downto](#L001200), [times](#L001204) も参照してください。

### times {|*n*| ... }



self 回だけ (0 から self-1 まで) 繰り返します。 self が負であれば何もしません。

self を返します。

[upto](#L001211), [downto](#L001200), [step](#L001203) も参照してください。

### to_f



値を浮動小数点数 ([Float](sc_float.md)) に変換します。

### to_s([*base*])



整数を 10 進文字列表現に変換します。

引数を指定すれば、それを基数とした文字列表現に変換します。 基数として 2 ～ 36 以外を指定した場合は例外 [ArgumentError](s_exceptions.md#ArgumentError) が発生します。

```

p 10.to_s(2) # => "1010"
p 10.to_s(8) # => "12"
p 10.to_s(16) # => "a"
p 35.to_s(36) # => "z"
```



### upto(*max*) {|*n*| ... }



self から *max* まで 1 ずつ増やしながら繰り返します。 self > max であれば何もしません。

self を返します。

[downto](#L001200), [step](#L001203), [times](#L001204) も参照してください。

######
