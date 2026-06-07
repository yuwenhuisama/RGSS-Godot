# IO


IO クラスは基本的な入出力機能を実装します。

## スーパークラス


- [Object](sc_object.md)


## インクルードされているモジュール


- [Enumerable](sm_enumerable.md)


## メソッド



### binmode



ストリームをバイナリモードにします。 バイナリモードから通常のモードに戻す方法は再オープンしかありません。

self を返します。

### close



入出力ポートをクローズします。close に失敗した場合は例外 [Errno::EXXX](s_exceptions.md#Errno) が発生します。

nil を返します。

### each_line {|*line*| ... }



IO ポートから 1 行ずつ読み込みます。

self を返します。

### each_byte {|*ch*| ... }



IO ポートから 1 バイトずつ読み込みます。

self を返します。

### eof?



ストリームがファイルの終端に達した場合真を返します。

### pos



ファイルポインタの現在の位置を返します。

### pos=*n*



ファイルポインタを指定位置に移動します。

### read([*length*])



*length* バイト読み込んで、その文字列を返します。 *length* が省略されたときには、EOF までの 全てのデータを読み込みます。

IO がすでに EOF に達していれば nil を返します。

データの読み込みに失敗した場合は例外 [Errno::EXXX](s_exceptions.md#Errno) が発生しま す。*length* が負の場合、例外 [ArgumentError](s_exceptions.md#ArgumentError) が発生します。

### readlines([*rs*])



データを全て読み込んで、その各行を要素としてもつ配列を返します。 IO がすでに EOF に達していれば空配列 [] を返します。

行の区切りは引数 *rs* で指定した文字列になります。*rs* の デフォルト値は "\n" です。

*rs* に nil を指定すると行区切りなしとみなします。 空文字列 "" を指定すると連続する改行を行の区切りとみなします (パラグラフモード) 。

### write(*str*)



IO ポートに対して *str* を出力します。*str* が文字列でなけ れば to_s による文字列化を試みます。

実際に出力できたバイト数を返します。出力に失敗した場合は例外 [Errno::EXXX](s_exceptions.md#Errno) が発生します。

######
