# Exception


全ての例外の祖先のクラスです。

サブクラスについては[組み込み例外クラス](s_exceptions.md)を 参照してください。

## スーパークラス


- [Object](sc_object.md)


## クラスメソッド



### Exception.new([*error_message*])



例外オブジェクトを生成して返します。引数としてエラーメッセージを表 す文字列を与えることができます。このメッセージは属性 [message](#L000732) の値になり、デフォルトの例外ハンドラで表示 されます。

## メソッド



### exception([*error_message*])



引数を指定しない場合は self を返します。そうでなければ、自身のコピー を生成し、[message](#L000732) 属性を *error_message* にし て返します。

[raise](s_functions.md#L000388) は、実質的に、例外オブジェクトの exception メソッドの呼び出しです。

### backtrace



バックトレース情報を返します。

-

"#{sourcefile}:#{sourceline}:in `#{method}'"

(メソッド内の場合)
-

"#{sourcefile}:#{sourceline}"

(トップレベルの場合)


という形式の [String](sc_string.md) の配列です。

### message


エラーメッセージをあらわす文字列を返します。

######
