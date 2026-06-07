# MatchData


正規表現のマッチに関する情報を扱うためのクラス。 このクラスのインスタンスは、

- [Regexp.last_match](sc_regexp.md#L001314)
- [Regexp#match](sc_regexp.md#L001322)
- [$~](s_variables.md#L000428)


などにより得られます。

## スーパークラス


- [Object](sc_object.md)


## メソッド



### self[n]



*n* 番目の部分文字列を返します。0 はマッチ全体を意味します。 *n* の値が負のときには末尾からのインデックスとみなします (末尾の 要素が -1 番目) 。*n* 番目の要素が存在しないときには nil を 返します。

```

/(foo)(bar)(BAZ)?/ =~ "foobarbaz"
p $~.to_a # => ["foobar", "foo", "bar", nil]
p $~[0] # => "foobar"
p $~[1] # => "foo"
p $~[2] # => "bar"
p $~[3] # => nil (マッチしていない)
p $~[4] # => nil (範囲外)
p $~[-2] # => "bar"
```



### post_match



マッチした部分より後ろの文字列を返します。

### pre_match



マッチした部分より前の文字列を返します。

### to_a



[$&](s_variables.md#L000427), [$1](s_variables.md#L000432), [$2](s_variables.md#L000433), ... を格納した配列を返します。

### to_s



マッチした文字列全体を返します。

######
