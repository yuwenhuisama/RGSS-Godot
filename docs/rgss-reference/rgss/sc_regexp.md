# Regexp


[正規表現](appendix01.md)の クラス。[正規表現リテラル](syntax03.md#L000274)を 参照してください。

## スーパークラス


- [Object](sc_object.md)


## クラスメソッド



### Regexp.last_match



カレントスコープで最後に行った正規表現マッチの [MatchData](sc_matchdata.md) オブジェクトを返します。 このメソッドの呼び出しは [$~](s_variables.md#L000428) の 参照と同じです。

```

/(.)(.)/ =~ "ab"
p Regexp.last_match # => #<MatchData:0x4599e58>
p Regexp.last_match[0] # => "ab"
p Regexp.last_match[1] # => "a"
p Regexp.last_match[2] # => "b"
p Regexp.last_match[3] # => nil
```



### Regexp.last_match([*nth*])



整数 *nth* が 0 の場合、マッチした文字列を返します ([$&](s_variables.md#L000427)) 。それ以外では、*nth* 番目の 括弧にマッチした部分文字列を返します ([$1](s_variables.md#L000432), [$2](s_variables.md#L000433), ...) 。 対応する括弧がない場合やマッチしなかった場合には nil を返します。

```

/(.)(.)/ =~ "ab"
p Regexp.last_match # => #<MatchData:0x4599e58>
p Regexp.last_match(0) # => "ab"
p Regexp.last_match(1) # => "a"
p Regexp.last_match(2) # => "b"
p Regexp.last_match(3) # => nil
```



正規表現全体がマッチしなかった場合、引数なしの Regexp.last_match は nil を返すため、 last_match[1] の形式では例外 [NameError](s_exceptions.md#NameError) が発生します。 対して、last_match(1) は nil を返します。

## メソッド



### *self* =~ *string*


### *self* === *string*



文字列 *string* との正規表現マッチを行います。引数が文 字列でないか、マッチしなければ false を、マッチすれば true を返します。

組み込み変数 [$~](s_variables.md#L000428) にマッチに関する情報が 設定されます。

*string* が nil でも [String](sc_string.md) オブジェクトでもなければ例外 [TypeError](s_exceptions.md#TypeError) が 発生します。

### match(*str*)



[MatchData](sc_matchdata.md) オブジェクトを返す点を除い て、self =~ str と同じです。マッチしなかった場合 nil を返します。

正規表現にマッチした部分文字列だけが必要な場合に、

```

bar = /foo(.*)baz/.match("foobarbaz").to_a[1]

_, foo, bar, baz = */(foo)(bar)(baz)/.match("foobarbaz")
```



のように使用できます (to_a は、マッチに失敗した場合を考慮しています) 。

### to_s



正規表現の文字列表現を生成して返します。返される文字列は他の正規表 現に埋め込んでもその意味が保持されるようになっています。

```

re = /foo|bar|baz/i
p re.to_s # => "(?i-mx:foo|bar|baz)"
p /#{re}+/o # => /(?i-mx:foo|bar|baz)+/
```



ただし、後方参照を含む正規表現は意図通りにはならない場合があります。 これは現状、後方参照を番号でしか指定できないためです。

```

re = /(foo|bar)\1/ # \1 は、foo か bar
p /(baz)#{re}/ # \1 は、baz

# => /(baz)(?-mix:(foo|bar)\1)/
```



######
