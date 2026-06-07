# String


文字列クラス。任意の長さの文字列を扱うことができま す。[文字列リテラル](syntax03.md#L000254)を参照してください。

## スーパークラス


- [Object](sc_object.md)


## インクルードしているモジュール


- [Comparable](sm_comparable.md)
- [Enumerable](sm_enumerable.md)


## メソッド



### *self* + *other*



文字列を連結した新しい文字列を返します。

### *self* * *times*



文字列の内容を *times* 回だけ繰り返した新しい文字列を作成して 返します。

### *self* <=> *other*



self と *other* を ASCII コード順で比較して、self が大きい ときに正、等しいときに 0、小さいときに負の整数を返します。

### *self* == *other*



文字列が等しいかどうか判定します。

### self[*nth*, *len*]



*nth* 文字番目から長さ *len* 文字の部分文字列を返しま す。*nth* が負の場合は文字列の末尾から数えます。

*nth* が範囲外を指す場合は nil を返します。

### self[regexp]



*regexp* にマッチする最初の部分文字列を返します。組み込み変数 [$~](s_variables.md#L000428) にマッチに関する情報が設定されます。

*regexp* にマッチしない場合 nil を返します。

```

p "foobar"[/bar/] # => "bar"
```



### self[*nth*, *len*]=*val*



*nth* 文字番目から長さ *len* 文字の部分文字 列を文字列 *val* で置き換えます。*nth* が負の場 合は文字列の末尾から数えます。

*val* を返します。

### self[regexp]=val



正規表現 *regexp* にマッチする最初の部分文字列を文字列 *val* で置き換えます。

正規表現がマッチしなければ例外 [IndexError](s_exceptions.md#IndexError) が発生します。

*val* を返します。

### clone


### dup



文字列と同じ内容を持つ新しい文字列を返します。フリーズした文字列の clone はフリーズされた文字列を返しますが、dup は内容の 等しいフリーズされていない文字列を返します。

### concat(*other*)



文字列 *other* の内容を self に連結します。self を 返します。

### downcase


### downcase!



文字列中のアルファベット大文字をすべて小文字に置き換えます。

downcase は変更後の文字列を生成して返します。 downcase! は self を変更して返しますが、置換が起こら なかった場合は nil を返します。

[upcase](#L001450) も参照してください。

### each_line {|*line*| ... }



文字列中の各行に対して繰り返します。

self を返します。

### each_byte {|*byte*| ... }



文字列の各バイトに対して繰り返します。self を返します。

### empty?



文字列が空 (つまり長さ 0) のとき、真を返します。

### gsub(*pattern*) {|*matched*| .... }


### gsub!(*pattern*) {|*matched*| .... }



文字列中で *pattern* にマッチする部分*全て*を、 ブロックを評価した結果で置換を行います。ブロックには引数として マッチした部分文字列が渡されます。 ブロックの中からは組み込み変数 [$<digits>](s_variables.md) を参照できます。

```

p 'abcabc'.gsub(/b/) {|s| s.upcase } # => "aBcaBc"
p 'abcabc'.gsub(/b/) { $&.upcase } # => "aBcaBc"
p 'abbbcd'.gsub(/a(b+)/) { $1 } # => "bbbcd"
```



gsub は置換後の文字列を生成して返します。gsub! は self を変更して 返しますが、置換が起こらなかった場合は nil を返します。

[sub](#L001433) も参照してください。

### *include?(*substr*)*



文字列中に部分文字列 *substr* が含まれていれば真を返します。

*substr* が 0 から 255 の範囲の [Fixnum](sc_fixnum.md) の場合、文字コー ドとみなして、その文字が含まれていれば真を返します。

### *index(*pattern*[, *pos*])*



部分文字列の探索を左端から右端に向かって行います。見つかった部分文 字列の左端の位置を返します。見つからなければ *nil* を返します。

引数 *pattern* には探索する部分文字列の指定を文字列、文字コー ドを示す 0 から 255 の整数、正規表現のいずれかで指定します。

*pos* が与えられた時にはその位置から探索します。*pos* の省 略時の値は 0 です。

### insert(*nth*, *other*)



*nth* 番目の文字の直前に文字列 *other* を挿入 します。self を返します。

```

p "foobaz".insert(3, "bar") # => "foobarbaz"
```



### to_sym



文字列に対応するシンボル値 ([Symbol](sc_symbol.md)) を返します。

シンボルに対応する文字列を得るには [Symbol#id2name](sc_symbol.md#L001480) を使います。

```

p "foo".to_sym # => :foo
p "foo".to_sym.to_s == "foo" # => true
```



### length


### size



文字列の文字数を返します。

### scan(*re*)

### scan(*re*) {|*s*| ... }



self に対して正規表現 *re* で繰り返しマッチを行い、マッ チした部分文字列の配列を返します。

```

p "foobarbazfoobarbaz".scan(/ba./)
# => ["bar", "baz", "bar", "baz"]

p "あいうえお".scan(/./)
# => ["あ", "い", "う", "え", "お"]
```



ブロックを指定して呼び出した場合は、マッチした部分文字列 (括弧を含 む場合は括弧で括られたパターンにマッチした文字列の配列) をブロック のパラメータとします。ブロックを指定した場合は self を返しま す。

```

"foobarbazfoobarbaz".scan(/ba./) {|s| p s}
# => "bar"
 "baz"
 "bar"
 "baz"
```



### slice(*nth*, *len*)


### slice(*regexp*)



[self[]](#L001349) と同じです。

### slice!(*nth*, *len*)


### slice!(*regexp*)



指定した範囲 ([self[]](#L001349) 参照) を文字列から取り除いたう えで取り除いた部分文字列を返します。

引数が範囲外を指す場合は nil を返します。

### sub(*pattern*) {|*matched*| ... }


### sub!(*pattern*) {|*matched*| ... }



文字列中で *pattern* に*最初に*マッチする部分を、 ブロックを評価した値で置き換えます。

sub は置換後の文字列を生成して返します。 sub! は self を変更して返しますが、置換が起こら なかった場合は nil を返します。

マッチを一度しか行わない点を除けば [gsub](#L001390) と 同じです。

### to_f



文字列を 10 進数表現と解釈して、 浮動小数点数 [Float](sc_float.md) に変換します。

### to_i([*base*])



文字列を数値表現と解釈して、整数に変換します。

基数 *base* を指定することでデフォルトの 10 進以外 に 2 ～ 36 進数への変換を行うことができます。

### upcase


### upcase!



文字列中のアルファベット小文字をすべて大文字に置き換えます。

upcase は置換後の文字列を生成して返します。 upcase! は self を変更して返しますが、置換が起こら なかった場合は nil を返します。

[downcase](#L001383) も参照してください。

######
