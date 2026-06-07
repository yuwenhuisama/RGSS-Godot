# タイトル画面の改造


- [ウィンドウの透明化](#opacity)
- [コマンドの変更](#command)
- [フォントの変更](#font)
- [アライメントの変更](#align)
- [最後に](#afterword)


最後に、ウィンドウの挙動の簡単なカスタマイズを行って、学習を 終わることにしましょう。

例として、タイトル画面で［ニューゲーム］などを表示する コマンドウィンドウの改造を行います。自作の画像を使ってタイトル 画面をデザインする場合、コマンドウィンドウの表示も変更することで、 よりオリジナリティを出すことができます。

## ウィンドウの透明化


Window_TitleCommand クラスの改造をしていきましょう。まずは initialize の再定義を行います。

```

class Window_TitleCommand
 alias xxx001_initialize initialize
 def initialize
 xxx001_initialize
 self.opacity = 0
 end
end
```



テストプレイを行うと、すぐに変化に気づくことと思います。opacity は RGSS 組み込みの [Window](../rgss/gc_window.md) で定義されている、不透明度を表すプロパティです。この値を 0 にすることで、ウィンドウを見えなくしているのです。

なお、ウィンドウの内容 (カーソルや［ニューゲーム］などの 文字列) は、opacity の影響を受けません。

## コマンドの変更


デザイン性の高い欧文フォントを使用するため、コマンド名を英語に 変更します。make_command_list を次のように再定義します。

```

class Window_TitleCommand
 def make_command_list
 add_command("New Game", :new_game)
 add_command("Continue", :continue, continue_enabled)
 add_command("Shutdown", :shutdown)
 end
end
```



今回は、古い make_command_list を呼び出さずに、メソッドの内容を 完全に上書きしています。デフォルトの動作を引き継ぎたくない場合に 有効な方法ですが、他の素材との競合の可能性も高くなりますので、この ような再定義方法を用いる際は十分に注意してください。

add_command の 3 番目の引数は、そのコマンドが有効状態で表示され るか否かを指定するものです。省略した場合は true とみなされます。

```

 add_command("Continue", :continue, continue_enabled)
```



ここで continue_enabled は［コンティニュー］が有効なら true を、無効なら false を返すメソッドです。実装としては、ゲームのセーブ データが存在するときに true を返すようになっています。

## フォントの変更


フォントを変更するために、create_contents メソッドを再定義します。create_contents は、ウィンドウ内容として表示するビットマップ contents を実際に作成、設定するためのメソッドです。

```

class Window_TitleCommand
 alias xxx001_create_contents create_contents
 def create_contents
 xxx001_create_contents
 contents.font.name = "Times New Roman"
 contents.font.bold = true
 contents.font.size = 28
 end
end
```



元の create_contents の呼び出しが終わった後、contents は Bitmap オブジェクトを指しているので、[タイマーの改造](301_timer.md)のときと同じ要領で各プロパティを変更すれば OK です。ここでは、フォント "Times New Roman" を太字、サイズ 28 で使用することを指定しました。詳しくは [Window](../rgss/gc_window.md)、[Bitmap](../rgss/gc_bitmap.md)、[Font](../rgss/gc_font.md) を参照してください。

## アライメントの変更


文字列を描画する際、左、中央、右のうちどこを基準に揃える かのことをアライメントと呼びます。これは [Bitmap](../rgss/gc_bitmap.md) の draw_text メソッドの、最後の引数に対応します。Window_Command クラスでは通常左揃えで描画していますが、alignment というメソッドを再定義することで簡単に変更ができます。

```

class Window_TitleCommand
 def alignment
 return 1
 end
end
```



このように、1 を返せば中央揃えで描画されます。0 ならデフォルトと同じ左揃え、2 なら右揃えとなります。

## 最後に


お疲れ様でした。「スクリプト入門」はこれで終了です。

実践編では比較的簡単な改造を通して、スクリプト素材の作成を どのような流れで行っていくのかを解説しました。基礎編と解読編で学習した 知識を併せれば、ここで解説できなかった部分も解読、改造していくことが できるはずです。[RGSS リファレンス](../rgss/index.md)を有効に活用してください。もし、メソッドやクラスの説明が見つけられない 場合は、ヘルプの「検索」を使用してみると良いでしょう。

RGSS を使いこなせば大抵のことは実現できますが、いきなり 「戦闘システムの自作」というような高い目標を立ててしまうと挫折しやすく なってしまいます。自分にできそうなことから始めて技術を磨いていくことを お勧めします。インターネットで公開されているスクリプト素材の解読を 試みることも、大いに助けになるでしょう。

######
