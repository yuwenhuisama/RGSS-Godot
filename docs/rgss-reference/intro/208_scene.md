# シーンの管理


- [Main セクション](#main)
- [SceneManager モジュール](#manager)
- [シーンクラス](#scene)
- [シーンの基本処理](#base)
- [シーンクラスの種類](#kind)
- [シーン遷移](#trans)


マップ画面やメニュー画面など、ゲーム内で通常「画面」と呼ぶ概念を、 プログラムでは**シーン**と呼びます。 各シーンの遷移は、SceneManager モジュールによって管理されます。

## Main セクション


はじめに、一番下にある Main セクションの内容を確認しましょう。 コメントを除くと、Main セクションの内容は 1 行だけです。

```

rgss_main { SceneManager.run }
```



実は、プリセットのスクリプトの中で、モジュール定義やクラス定義の 外にあるのはこれだけです。ある意味で、スクリプトの本当の実行開始地点は ここだと考えることもできるでしょう。

[rgss_main](../rgss/g_functions.md#rgss_main) というのは RGSS3 で新たに加わった組み込み関数です。この関数は、 基本的には { }で囲った部分を一度だけ実行しますが、その途中で F12 キーによってゲームのリセットが行われたときは最初に戻るという処理を 行います。リセット処理を無視すると、この行では SceneManager モジュールの run メソッドを呼び出しているだけということです。

## SceneManager モジュール


SceneManager モジュールは、リストの上の方にあったにも関わらず、 今までまったく内容に触れていませんでした。SceneManager はシーンの遷移を管理するモジュールです。

まず、先ほど最初に呼び出されることを確認した、run メソッドに注目してください。

```

 def self.run
 DataManager.init
 Audio.setup_midi if use_midi?
 @scene = first_scene_class.new
 @scene.main while @scene
 end
```



内容は 4 行ですが、1 行ずつ見ていきましょう。

```

 DataManager.init
```



DataManager モジュールの init メソッドを呼び出します。[データベース](201_database.md)のロードや[ゲームオブジェクト](205_gameobjects.md)の初期化が この中で行われています。

```

 Audio.setup_midi if use_midi?
```



データベースの [システム] タブで [起動時に MIDI を初期化] のオプションがチェックされている場合、MIDI の初期化を行います。

```

 @scene = first_scene_class.new
```



同じ SceneManager モジュールの first_scene_class メソッドを呼び出し、 戻り値として返されたクラスのインスタンスを作成、インスタンス変数 @scene にそれを代入します。これについては次節で詳しく解説します。

```

 @scene.main while @scene
```



ここで使われている while は**修飾子**形式です。if や unless と同様、while もこのような使い方ができるのです。 基礎編で学習した基本的な[ループ](106_loop.md)の文法で書き直すと、次のようになります。

```

 while @scene
 @scene.main
 end
```



内容としては、インスタンス変数 @scene が nil でない間、@scene の main メソッドを呼び出し続けています。一見すると無限ループのように見えるかも しれませんが、main メソッドの中で SceneManager にアクセスし、@scene の指すオブジェクトを外から変更するという構造になっているため、 問題はありません。

## シーンクラス


再び 3 行目に戻ります。

```

 @scene = first_scene_class.new
```



ここで呼び出されている first_scene_class メソッドの定義を見てみましょう。

```

 def self.first_scene_class
 $BTEST ? Scene_Battle : Scene_Title
 end
```

 ? および : という記号は演算子形式の[条件分岐](105_branch.md)です。$BTEST という変数の値が真なら Scene_Battle を、偽なら Scene_Title を返すことになります。Scene_Battle や Scene_Title というのはクラス名ですが、Ruby ではこのように、クラスを メソッドの戻り値とすることもできるのです。

グローバル変数 $BTEST は RGSS によって自動的に設定される変数で、 戦闘テストとして起動されたか否かを表しています。すなわち、戦闘テストで あればバトル画面、そうでなければタイトル画面が初期画面になります。

## シーンの基本処理


SceneManager から呼び出される main メソッドは、シーンの最上位 クラスである Scene_Base クラスで定義されています。 確認しておきましょう。

```

 def main
 start
 post_start
 update until scene_changing?
 pre_terminate
 terminate
 end
```



ここでは、次の五つのメソッドを順番に呼び出しています。

| メソッド | 内容 |
| --- | --- |
| start | 開始処理 |
| post_start | 開始後処理 |
| update | フレーム更新 |
| pre_terminate | 終了前処理 |
| terminate | 終了処理 |



開始処理と開始後処理、終了処理と終了前処理の違いは、主に その画面のグラフィックが実際に表示されているか否かです。 サブクラスでの再定義で処理を追加する際にそのタイミングを制御 しやすいようにするため、このように細分化されています。

```

 update until scene_changing?
```



真ん中にあるこの記述は、シーン遷移 (画面切り替え) が指示される までの間、update メソッドを呼び出し続けるということを示しています。 各シーンでフレームごとの処理が必要な場合は、この update メソッドを 再定義することになります。

## シーンクラスの種類


各シーンクラスに対応する画面を次の表に示します。クラス名とセクション名 は完全に一対一で対応しています。

| クラス | 内容 | スーパークラス |
| --- | --- | --- |
| Scene_Title | タイトル画面 | Scene_Base |
| Scene_Map | マップ画面 | Scene_Base |
| Scene_MenuBase | メニュー画面系の基本処理 | Scene_Base |
| Scene_Menu | メニュー画面 | Scene_MenuBase |
| Scene_ItemBase | アイテム画面とスキル画面の共通処理 | Scene_MenuBase |
| Scene_Item | アイテム画面 | Scene_ItemBase |
| Scene_Skill | スキル画面 | Scene_ItemBase |
| Scene_Equip | 装備画面 | Scene_MenuBase |
| Scene_Status | ステータス画面 | Scene_MenuBase |
| Scene_File | セーブ画面とロード画面の共通処理 | Scene_MenuBase |
| Scene_Save | セーブ画面 | Scene_File |
| Scene_Load | ロード画面 | Scene_File |
| Scene_End | ゲーム終了画面 | Scene_MenuBase |
| Scene_Shop | ショップ画面 | Scene_MenuBase |
| Scene_Name | 名前入力画面 | Scene_MenuBase |
| Scene_Debug | デバッグ画面 | Scene_MenuBase |
| Scene_Battle | バトル画面 | Scene_Base |
| Scene_Gameover | ゲームオーバー画面 | Scene_Base |



メニュー画面系の基本となる Scene_MenuBase クラスは、非常に多くの クラスで継承されています。このクラスには、マップ画面をぼかした画像を 背景として表示するなどの処理が含まれています。

## シーン遷移


ゲーム中にシーンを切り替えるメソッドは、goto、call、return の 3 種類があります。

一番単純なのは goto で、たとえばゲームオーバー画面のように 一方通行の遷移を行う際に使用します。

```

SceneManager.goto(Scene_Gameover)
```



call は、メニュー画面のように、呼び出し元のシーンに戻ることが ある場合に使用します。

```

SceneManager.call(Scene_Menu)
```



return は、call で呼び出されたシーンから元のシーンに戻す際に 使用します。

```

SceneManager.return
```



シーン遷移が実際にどのように使われるかは、続く実践編でも 解説します。

なお、前作までは $scene というグローバル変数にシーンオブジェクト を代入する形でシーン遷移を行っていましたが、より本格的な SceneManager モジュールの導入に伴い、その方式は廃止されました。以前からのユーザーの 方はご注意ください。

######
