# File


ファイルアクセスのためのクラス。通常 [open](s_functions.md#L000379) または [File.open](#L000976) を使って生成します。

オープンしたまま参照されなくなった File オブジェクトは、次のガーベージ コレクトで close されて捨てられます。

## スーパークラス


- [IO](sc_io.md)


## クラスメソッド



### File.mtime(*filename*)



ファイルの最終更新時刻 ([Time](sc_time.md) オブジェクト) を 返します。

取得に失敗した場合は例外 [Errno::EXXX](s_exceptions.md#Errno) が発生します。

### File.basename(*filename*[, *suffix*])



*filename* の一番後ろのスラッシュに続く要素を返します。もし、 引数 *suffix* が与えられて、かつそれが *filename* の末尾に 一致するなら、それを取り除いたものを返します。

```

p File.basename("ruby/ruby.c") # => "ruby.c"
p File.basename("ruby/ruby.c", ".c") # => "ruby"
p File.basename("ruby/ruby.c", ".*") # => "ruby"
p File.basename("ruby/ruby.exe", ".*") # => "ruby"
```



[File.dirname](#L000967), [File.extname](#L000969) も参照。

### File.delete(*filename* ... )



ファイルを削除します。削除したファイルの数を返します。削除に失敗し た場合は例外 [Errno::EXXX](s_exceptions.md#Errno) が発生します。

このメソッドは通常ファイルの削除用で、ディレクトリを削除することは できません。

### File.dirname(*filename*)



*filename* の一番後ろのスラッシュより前を文 字列として返します。スラッシュを含まないファイル名に対しては "."(カレントディレクトリ) を返します。

```

p File.dirname("dir/file.ext") # => "dir"
p File.dirname("file.ext") # => "."
p File.dirname("foo/bar/") # => "foo"
p File.dirname("foo//bar") # => "foo"
```



[File.basename](#L000960), [File.extname](#L000969) も参照。

### File.expand_path(*path*[, *default_dir*])



*path* を絶対パスに展開した文字列を返します。 *path* が相対パスであれば *default_dir* を基準にします。 *default_dir* が nil かまたは与えられなかったときにはカ レントディレクトリが使われます。

```

p File.expand_path("..") # => "/home/matz/work"
p File.expand_path("..", "/tmp") # => "/"
```



### File.extname(*filename*)



ファイル名 *filename* の拡張子部分 (最後の "." に続く文字列) を 返します。ディレクトリ名に含まれる "." や、ファイル名先頭の "." は拡張子の一部としてはみなされません。*filename* に拡張子が含 まれない場合は空文字列を返します。

```

p File.extname("foo/foo.txt") # => ".txt"
p File.extname("foo/foo.tar.gz") # => ".gz"
p File.extname("foo/bar") # => ""
p File.extname("foo/.bar") # => ""
p File.extname("foo.txt/bar") # => ""
p File.extname(".foo") # => ""
```



[File.basename](#L000960), [File.dirname](#L000967) も参照。

### File.open(*path*[, *mode*])

### File.open(*path*[, *mode*]) {|*file*| ... }



*path* で指定されるファイルをオープンし、ファイルオブジェクトを 返します。ファイルのオープンに失敗した場合は例外 [Errno::EXXX](s_exceptions.md#Errno) が発生します。

引数 *mode* については 組み込み関数 [open](s_functions.md#L000379) と同じです。

open() はブロックを指定することができます。 ブロックを指定して呼び出した場合は、ファイルオブジェクトを 与えられてブロックが実行されます。ブロックの実行が終了すると、 ファイルは自動的にクローズされます。

ブロックが指定されたときのこのメソッドの戻り値はブロックの実行結果 です。

### File.rename(*from*, *to*)



ファイルの名前を変更します。ディレクトリが異なる場合には移動も行い ます。移動先のファイルが存在するときには上書きされます。

ファイルの移動に成功した場合 0 を返します。失敗した場合は例外 [Errno::EXXX](s_exceptions.md#Errno) が発生します。

## メソッド



### mtime



ファイルの最終更新時刻 ([Time](sc_time.md) オブジェクト) を 返します。

取得に失敗した場合は例外 [Errno::EXXX](s_exceptions.md#Errno) が発生します。

### path



オープンしているファイルのパスを返します。

######
