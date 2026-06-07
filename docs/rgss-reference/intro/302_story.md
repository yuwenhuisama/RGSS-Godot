# あらすじ画面の作成


- [コマンドの追加](#command)
- [コマンドハンドラの設定](#handler)
- [シーンの作成](#scene)
- [ウィンドウの作成](#window)
- [ゲーム内変数の参照](#variable)


メニュー画面に新しいコマンドを追加し、独自のシーンを呼び出す 方法を解説します。

例として、画面全体にウィンドウを表示する [あらすじ] コマンドを作成します。

## コマンドの追加


メニュー画面で [アイテム] や [スキル] などのコマンドを選択する ウィンドウに対応するクラスは、Window_MenuCommand です。

Window_MenuCommand セクションに移動し、内容をざっと確認してみて ください。add_original_commands という空のメソッドがありますね。 VX Ace ではこれを再定義することで、コマンドを簡単に追加することが できるようになっています。具体的には次のように記述します。

```

class Window_MenuCommand
 alias xxx001_add_original_commands add_original_commands
 def add_original_commands
 xxx001_add_original_commands
 add_command("あらすじ", :story)
 end
end
```



これを素材の位置に追加し、テストプレイにて、メニュー画面に コマンドが追加されていることを確認してください。

空のメソッドなのにエイリアスを使っている理由は、他のスクリプト素材が さらに再定義している可能性を考慮した競合対策です。 繰り返しになりますが、ネット上などで独自の素材を配布する場合は、xxx001 の部分を変更するようにしてください。

```

 add_command("あらすじ", :story)
```



add_command メソッドは、解読編の[ウィンドウの管理](207_windows.md)にて解説したものです。 ここでは「あらすじ」という名前のコマンドを :story というシンボルに 関連付けるように指示しています。

## コマンドハンドラの設定


コマンドが実際に選択されたときの処理を行っているの は、Window_MenuCommand ではなく Scene_Menu クラスです。Scene_Menu セクションを開き、内容を確認してください。create_command_window メソッドの中に次のような行があります。

```

 @command_window.set_handler(:item, method(:command_item))
```



これも[ウィンドウの管理](207_windows.md)で解説 したように、:item に対応するコマンドが選択されたとき、command_item メソッドを呼び出すという指定です。

呼び出し先の command_item は次のような定義になって います。解読編の[シーンの管理](208_scene.md)で解説した、シーンの呼び出しをここで使用しています。

```

 def command_item
 SceneManager.call(Scene_Item)
 end
```



したがって、:story というシンボルを関連付けたコマンドを選択 したときに Scene_Story に遷移させるのであれば、スクリプトは次の ようになります。基本的にはプリセットのスクリプトに倣って同じように 書けば良いだけです。

```

class Scene_Menu
 alias xxx001_create_command_window create_command_window
 def create_command_window
 xxx001_create_command_window
 @command_window.set_handler(:story, method(:command_story))
 end
 def command_story
 SceneManager.call(Scene_Story)
 end
end
```



## シーンの作成


遷移先の Scene_Story クラスを作成します。今回サンプルとして 作成する [あらすじ] 画面はメニュー画面系なので、Scene_MenuBase をスーパークラスとして指定します。

```

class Scene_Story < Scene_MenuBase
end
```



シーン開始時に呼び出される start メソッドをオーバーライド し、ウィンドウの作成処理を行います。ここで使用する Window_Story クラスは後で定義します。

```

class Scene_Story < Scene_MenuBase
 def start
 super
 @story_window = Window_Story.new
 @story_window.set_handler(:cancel, method(:return_scene))
 end
end
```



Window_Selectable クラスから派生したウィンドウは、:cancel という シンボルのハンドラを設定することで、アクティブ状態のときにキャンセル ボタンが押されたときの処理を指定することができます。return_scene は Scene_Base クラスで定義されているメソッドで、名前通り、元のシーン に戻る処理を行います。

なお、シーンクラスの中でインスタンス変数に直接代入されたウィンドウは Scene_Base クラスが自動的に解放するようになっているため、dispose の記述はここでは必要ありません。

## ウィンドウの作成


あらすじ画面で表示するウィンドウ、Window_Story クラスを作成します。項目の選択処理は必要ありませんが、上述の通り :cancel のハンドリング処理を利用したいので、Window_Selectable クラスから派生させます。

```

class Window_Story < Window_Selectable
 def initialize
 super(0, 0, Graphics.width, Graphics.height)
 draw_text_ex(4, 0, "ウィンドウに描画する文字列")
 activate
 end
end
```



initialize は、基礎編の[クラス定義](112_class.md)でも解説した初期化用のメソッドです。オブジェクトが作成されたときに 自動的に呼び出されます。super は、スーパークラスの同名メソッドを 呼び出す予約語で、ここでは Window_Selectable クラスの initialize メソッドを呼び出しています。

Graphics.width と Graphics.height は、それぞれ画面の幅と高さを 取得するメソッドです。これにより、画面いっぱいのサイズのウィンドウを 作成することを指示しています。

draw_text_ex はウィンドウ内に文字列を描画するメソッドで、\C[n] や \V[n] などの制御文字にも対応しています。ただし、Ruby の文字列処理でも \ という記号が特別な意味を持っているため、ダブル クォートで囲む形式の文字列を使用する場合は \\C のように二重に記述する必要があります。

activate は、ウィンドウをアクティブ状態にするメソッドです。 これにより :cancel のハンドリングが有効になります (:cancel 以外のハンドラは今回設定していませんから、たとえば決定ボタンでは 何も起こりません) 。

以上を打ち込めば、テストプレイ可能です。さあ、実行してみましょう。

## ゲーム内変数の参照


イベントの進行状況によって表示内容を変化させるには、ツクールの 変数機能を利用するのが簡単です。たとえば変数 7 番なら $game_variables[7] で参照できます。ゲーム内変数を操作するには、 イベントコマンド［変数の操作］を使うか、F9 キーでデバッグ画面を出して 操作してください。

```

class Window_Story < Window_Selectable
 def initialize
 super(0, 0, Graphics.width, Graphics.height)
 case $game_variables[7]
 when 0
 story = "進行段階 0 のときのあらすじ"
 when 1
 story = "進行段階 1 のときのあらすじ"
 when 2
 story = "進行段階 2 のときのあらすじ"
 end
 draw_text_ex(4, 0, story)
 activate
 end
end
```



このサンプルでは case ～ end 形式の条件分岐を使用していますが、たとえば[ハッシュ](111_hash.md)などを使えばもっと綺麗に書くことも 可能です。余裕のある方は挑戦してみてください。

######
