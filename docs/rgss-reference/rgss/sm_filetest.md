# FileTest


ファイルの検査関数を集めたモジュール。

## モジュール関数



### FileTest.exist?(*filename*)



*filename* が存在するとき、真を返します。

### FileTest.directory?(*filename*)



*filename* がディレクトリのとき、真を返します。

### FileTest.file?(*filename*)



*filaname* が通常ファイルであるとき、真を返します。

### FileTest.size(*filename*)



*filename* のサイズを返します。*filename* が存在しなければ 例外 [Errno::EXXX](s_exceptions.md#Errno) (おそらく Errno::ENOENT) が発生します。

######
