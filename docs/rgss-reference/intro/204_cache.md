# Cache モジュール


- [キャッシュとは何か](#what)
- [キャッシュの使い方](#use)
- [実装の詳細](#detail)
- [nil ガード](#nil_guard)
- [各メソッドの呼び出し](#methods)
- [ビットマップの作成](#bitmap)


Cache は、画像ファイルの読み込みを高速化するためのモジュールです。

## キャッシュとは何か


基礎編で[画像の表示](109_graphics.md)を行うとき に、[Bitmap](../rgss/gc_bitmap.md) というクラスを次のように 使用しました。

```

skeleton.bitmap = Bitmap.new("Graphics/Battlers/Skeleton")
```



このように、Bitmap クラスのインスタンスを作成するとき、引数として 画像のファイル名を指定することで、そのファイルを読み込むことができま す。

しかしながら、画像が必要になるたびに毎回ファイルを読み込んでいたの では実行効率が悪くなってしまいます。そこで、一度作成した Bitmap オブ ジェクトを保持しておくための仕組みを提供しているのが、この Cache モ ジュールなのです。

Cache (キャッシュ) とはもともと「貯蔵庫」という意味の英単語ですが、 コンピュータの世界では、「頻繁に用いられるデータを蓄えておくための 場所」という意味が定着しています。このモジュールの命名もそれに倣って います。

## キャッシュの使い方


Cache モジュールの内部がどのような定義になっているかということより、 どのように使うのかということのほうが重要です。

実際には次のような使用方法になります (注意: Cache モジュールの定義が 完了していない TEST セクションでは使用できません) 。

```

skeleton.bitmap = Cache.battler("Skeleton", 0)
```



このスクリプトは、キャッシュから 戦闘グラフィック "Skeleton" のビットマップを取得すると いう内容です。取得した Bitmap オブジェクトが戻り値と なります。Bitmap.new を直接呼び出す場合のよう に、"Graphics/Battlers/" というフォルダ名を指定しなくて良い ようになっています。

2 番目の引数の「0」は、色相変化値を表しています。 値の範囲は 0 ～ 360 で、アニメーション グラフィックと戦闘グラフィックの 場合のみ指定します。

各種素材フォルダに対応するメソッドは以下の通りです。

| メソッド名 | 引数 | フォルダ |
| --- | --- | --- |
| Cache.animation | ファイル名、色相 | Graphics/Animations/ |
| Cache.battleback1 | ファイル名 | Graphics/Battlebacks1/ |
| Cache.battleback2 | ファイル名 | Graphics/Battlebacks2/ |
| Cache.battler | ファイル名、色相 | Graphics/Battlers/ |
| Cache.character | ファイル名 | Graphics/Characters/ |
| Cache.face | ファイル名 | Graphics/Faces/ |
| Cache.parallax | ファイル名 | Graphics/Parallaxes/ |
| Cache.picture | ファイル名 | Graphics/Pictures/ |
| Cache.system | ファイル名 | Graphics/System/ |
| Cache.tileset | ファイル名 | Graphics/Tilesets/ |
| Cache.title1 | ファイル名 | Graphics/Titles1/ |
| Cache.title2 | ファイル名 | Graphics/Titles2/ |



なお、Sound モジュールと同様、空のファイル名を指定してもエラーには ならないように設計されています。その場合は、32×32 の大きさの 空のビットマップを作成して返します。1×1 でないのは、使い方に よっては実行効率が悪くなるという、RGSS 内部の実装上の都合によりま す。

## 実装の詳細


キャッシュについての理解をより深めるために、実装がどのようになって いるのかを見ていきましょう。まずは Cache.battler メソッドからです。

```

 def self.battler(filename, hue)
 load_bitmap("Graphics/Battlers/", filename, hue)
 end
```



シンプルですね。引数として戦闘グラフィックのフォルダ名を追加 し、load_bitmap という別のメソッドを呼び出しているだけです。 では、呼び出し先の load_bitmap メソッドを見てみます。

```

 def self.load_bitmap(folder_name, filename, hue = 0)
 @cache ||= {}
 if filename.empty?
 empty_bitmap
 elsif hue == 0
 normal_bitmap(folder_name + filename)
 else
 hue_changed_bitmap(folder_name + filename, hue)
 end
 end
```



これは解読が大変そうです。細切れにして読んでいきましょう。

```

 def self.load_bitmap(folder_name, filename, hue = 0)
```



最上行はモジュールメソッドの定義ですね。フォルダ名、ファイル名、 色相を引数として取るように定義されています。色相 (hue) に指定されて いる「0」は**デフォルト引数**です。 これは[関数](107_function.md)の場合とまったく同じ です。

## nil ガード


2 行目の解読は厄介です。

```

 @cache ||= {}
```



これは **nil ガード**と呼ばれる、Ruby 特有のイディオムです。||= というのは OR 演算子と自己代入を組み合わせた もので、省略せずに書くと以下のようになります。

```

 @cache = @cache || {}
```



これでもまだ意味不明でしょう。|| 演算子は、主に[条件分岐](105_branch.md)で「または」ということを表すために 使うものですが、これはそれを応用した書き方なのです。

Ruby では、nil と false 以外の値は全て true として扱われます。 そして || 演算子は、左の値が true であればその値を、false であれば 右の値を返すという動作を行います。したがって、次のコードと同じと いうことになります。

```

 if @cache != nil
 @cache = @cache
 else
 @cache = {}
 end
```



{} という記号は何だったか覚えていますか？　これは、 空の[ハッシュ](111_hash.md)を作成する方法でした。 まとめると、@cache というインスタンス変数の値が nil のとき、 空のハッシュオブジェクトを作成して代入するという意味になり ます。インスタンス変数は、クラスで定義される通常のメソッドで 使用するのが一般的ですが、ここはモジュールメソッドの中です。 この場合、インスタンス変数は Cache モジュールそのものに属する 変数と解釈されます。

これは比較的上級な書き方なのですが、より短く簡潔に書くために プリセットのスクリプトでも使用しています。

## 各メソッドの呼び出し


続いて見ていきましょう。

```

 if filename.empty?
 empty_bitmap
 elsif hue == 0
 normal_bitmap(folder_name + filename)
 else
 hue_changed_bitmap(folder_name + filename, hue)
 end
```



長い条件分岐ですが、内容はさほど複雑ではありません。

まず filename が空文字列であるかを調べ、そうであるならば empty_bitmap というメソッドを呼び出してその値を返します。filename が空でなく、hue の値 (色相) が 0 であるなら、normal_bitmap を、 0 以外であるなら hue_changed_bitmap をそれぞれ呼び出します。

つまり load_bitmap メソッドは、その内部でさらに別のメソッドを 呼び出しているということです。このように、VX Ace のスクリプトは 比較的、処理をメソッド単位で細切れにして書かれている傾向があります。 このため初心者の方は解読に戸惑うかもしれませんが、メソッドの 再利用性や可読性を高めるための処置ですので、最終的にはこのほうが 良いと思うようになるでしょう。

念のため解説しておくと、

```

 folder_name + filename
```



これは単純な[文字列](104_string.md)の足し算 です。たとえば folder_name が "Graphics/Battlers/"、filename が "Skeleton" であるときは、それを連結した "Graphics/Battlers/Skeleton" になるということです。

## ビットマップの作成


続いて、normal_bitmap の実装を確認しておきます。

```

 def self.normal_bitmap(path)
 @cache[path] = Bitmap.new(path) unless include?(path)
 @cache[path]
 end
```



unless が右側についているのは、修飾子形式の[条件分岐](105_branch.md)です。ここでは、path に対応するビットマップがキャッシュに含まれていなければ 新規に画像ファイルを読み込み、含まれていればそれをそのまま返す という処理を行っています。

include? メソッドは次のような実装です。

```

 def self.include?(key)
 @cache[key] && !@cache[key].disposed?
 end
```



これは、@cache が指しているハッシュオブジェクトに key が含まれており、かつ、そのビットマップが解放されていない場合 という条件を判定しています。disposed? メソッドについては [Bitmap](../rgss/gc_bitmap.md) のリファレンスを参照してください。

Cache モジュールにはこのほか色相変化の処理などが含まれて いますが、特に見るべき個所はありませんので、解説は省略します。

######
