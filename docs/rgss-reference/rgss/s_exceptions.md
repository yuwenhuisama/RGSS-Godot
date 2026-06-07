# 組み込み例外クラス



### [Exception](sc_exception.md)

全ての例外の祖先のクラスです。


### *NoMemoryError*

大きすぎるメモリを一度に確保しようとしたときに発生します。

### *ScriptError*

スクリプトのエラーを表す例外です。


### *NotImplementedError*

実装されていない機能が呼び出されたときに発生します。

### *SyntaxError*

文法エラーがあったときに発生します。

### *StandardError*

この例外クラスとそのサブクラスは、[rescue 節](syntax05.md#L000314)でクラ スを省略したときにも捕捉できます。


### *ArgumentError*

引数の数が合っていないときや、値が正しくないときに発生します。

### *IndexError*

添字が範囲外のときに発生します。

### *IOError*

I/O でエラーが起きたときに発生します。


### *EOFError*

EOF (End Of File) に達したときに発生します。

### *LocalJumpError*

制御構造のジャンプ先が見つからないときに発生します。

### *NameError*

未定義のローカル変数や定数を使用したときに発生します。


### *NoMethodError*

定義されていないメソッドの呼び出しが行われたときに発生します。

### *RangeError*

範囲に関する例外。範囲外の数値変換 ([Bignum](sc_bignum.md) から [Fixnum](sc_fixnum.md) への変換) などにより発生します。


### *FloatDomainError*

正負の無限大や NaN (Not a Number) を [Bignum](sc_bignum.md) に変換しようと したり、NaN との比較を行ったときに発生します。

### *RegexpError*

正規表現のコンパイルに失敗した場合に発生します。

### *RuntimeError*

実行時例外です。例外を指定しない [raise](s_functions.md#L000388) の呼び出しはこの例外を発生させます。

### *SystemCallError*

システムコールが失敗したときに発生する例外です。


### *Errno::EXXX*

各 errno に対応する例外クラスです。実際のクラス名については [Errno](sm_errno.md) モジュールを参照してください。

### *SystemStackError*

スタックレベルが深くなりすぎたときに発生します。

### *TypeError*

不正な型を使用したときに発生します。

### *ZeroDivisionError*

0 で除算を行ったときに発生します。

### *SystemExit*

プログラムを終了させます。[exit](s_functions.md#L000363) を 参照してください。

### *fatal*

致命的なエラー (内部的なエラー) のときに発生します。このオブジェクトは通常の方法では見えません。

######
