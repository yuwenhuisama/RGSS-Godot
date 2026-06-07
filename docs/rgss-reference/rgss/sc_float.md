# Float


浮動小数点数のクラス。Float の実装は C 言語の double です。

## スーパークラス


- [Numeric](sc_numeric.md)


## メソッド



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

### finite?



数値が ∞ でも、NaN でもなければ真を返します

### infinite?



数値が +∞ のとき 1、-∞ のとき -1 を返します。それ以外は nil を返 します。浮動小数点数の 0 による除算は ∞ です。

```

inf = 1.0/0
p inf
p inf.infinite?

=> Infinity
 1

inf = -1.0/0
p inf
p inf.infinite?

=> -Infinity
 -1
```



### nan?



数値が NaN (Not a number) のとき真を返します。浮動小数点数 0 の 0 に よる除算は NaN です。

```

nan = 0.0/0.0
p nan
p nan.nan?

=> NaN
 true
```



######
