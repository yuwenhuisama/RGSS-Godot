# Range


範囲オブジェクトのクラス。[範囲式](syntax03.md#L000281)を 参照してください。

## スーパークラス


- [Object](sc_object.md)


## インクルードしているモジュール


- [Enumerable](sm_enumerable.md)


## クラスメソッド



### Range.new(*first*, *last*[, *exclude_end*])



*first* から *last* までの範囲オブジェクトを生成して 返します。*exclude_end* が真ならば終端を含まない範囲オブジェクトを 生成します。*exclude_end* 省略時には終端を含みます。

## メソッド



### *self* === *other*



このメソッドは主に [case](syntax05.md#L000301) 文での比較に用いられます。 *other* が範囲内に含まれているときに真を返します。

### begin


### first



最初の要素を返します。

### each {|*item*| ... }



範囲内の要素に対して繰り返します。

### end


### last



終端を返します。範囲オブジェクトが終端を含むかどうかは関係ありませ ん。

```

p (1..5).end # => 5
p (1...5).end # => 5
```



### exclude_end?



範囲オブジェクトが終端を含まないとき真を返します。

######
