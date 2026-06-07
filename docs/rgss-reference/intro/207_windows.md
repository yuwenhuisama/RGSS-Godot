# ウィンドウの管理


- [ウィンドウの基本](#basic)
- [ハンドラ](#handler)
- [コマンドウィンドウ](#command_window)
- [ウィンドウクラス一覧](#class_list)


メッセージウィンドウやステータスウィンドウをはじめとして、RPG では 非常に多くのウィンドウを扱わなければなりません。これらのウィンドウが どのように管理されているのかを解説します。

## ウィンドウの基本


Window_Xxxx という名前が付けられたセクションが大量にありますね。 例によってこれらはそのままクラス名に対応しています。その中でも特に 重要なのは、最初のふたつのクラスです。

| クラス | 内容 | スーパークラス |
| --- | --- | --- |
| Window_Base | 基本ウィンドウ | [Window](../rgss/gc_window.md) |
| Window_Selectable | 項目の選択ができるウィンドウ | Window_Base |



RGSS には [Window](../rgss/gc_window.md) という クラスがあらかじめ組み込まれています。このクラスは、ウィンドウの枠や 背景の描画、内容のスクロールといった基本的な処理を受け持っています。

Window_Base クラスはこの [Window](../rgss/gc_window.md) クラスを継承し、RPG のウィンドウに必要な基本機能を追加しています。 このクラスのもっとも重要な機能は、現在ウィンドウスキンとして設定されて いる画像ファイルを自動的に読み込む機能です。また、各種文字色もこの クラスで定義されています。VX Ace では、¥C[n] など基本的な制御文字の 処理もこのクラスで行うようになりました。

Window_Selectable クラスは、Window_Base クラスを継承し、方向ボタン などの入力を検知してカーソルを移動させる処理や、あらかじめウィンドウに 関連付けたメソッドを呼び出す処理などを追加したものです。たとえば アイテムの選択など、ゲームには何かを選択するウィンドウが頻繁に必要に なります。そのようなウィンドウに共通の機能を、このクラスで定義している のです。実際のカーソル移動処理は、update という名前のメソッドが呼び出さ れた時点で行われています。

ウィンドウの update メソッドを呼び出しているのは、後の章で解説 する**シーンクラス**です。

## ハンドラ


Window_Selectable クラスは「あらかじめウィンドウに関連付けたメソッド を呼び出す処理」を持つと説明しましたが、これを**ハンドラ**と呼びます。この概念は VX Ace にて新しく導入されました。

考え方としては、たとえば「決定ボタンを押したとき」や「キャンセル ボタンを押したとき」などに呼び出すメソッドをあらかじめ登録しておき、 実際にメソッドを呼び出す処理はウィンドウクラス側で行うということです。

まず、Window_Selectable の中ほどにある set_handler というメソッドを 探してください。

```

 def set_handler(symbol, method)
 @handler[symbol] = method
 end
```



これがハンドラをウィンドウに設定するためのメソッドです。内部で 使用しているインスタンス変数 @handler は、[ハッシュ](111_hash.md)オブジェクトです。

実際にハンドラを設定するときには、次のように呼び出されます。

```

 @window.set_handler(:cancel, method(:on_cancel))
```



これは on_cancel という名前のメソッドを、cancel という名前の ハンドラとして設定するという指定です。こうしておくと、キャンセル ボタンが押されたときに自動的に on_cancel メソッドが呼び出される ようになるわけです。method というのは [Object](../rgss/sc_object.md) クラスのメソッドで、引数として与えられた名前のメソッドを [Method](../rgss/sc_method.md) オブジェクトに変換する機能を持っています。

説明が前後しますが、メソッドやハンドラの名前を指定するときには シンボルを使用します。[画像の表示](109_graphics.md)の 最後の項でも簡単に触れましたが、シンボルは任意の文字列と一対一に対応 するオブジェクトで、コロン (":") に任意の文字を続けて 書くことで指定します。文字列に似ていますが、内部処理の効率性など から、文字列としての操作が必要ない場合はこちらを用います。 シンボルは [Symbol](../rgss/sc_symbol.md) クラスのインスタンスです。

Window_Selectable クラスは、ウィンドウがアクティブ状態 (カーソルが点滅している状態) のとき、次の 4 種類のハンドラを 必要に応じて呼び出します。

| シンボル | 内容 |
| --- | --- |
| :ok | 決定 |
| :cancel | キャンセル |
| :pageup | 前ページ (L) |
| :pagedown | 次ページ (R) |



なお、ハンドラが設定されていない場合は何も行いません。

## コマンドウィンドウ


Window_Selectable クラスから、さらに Window_Command クラスが派生します。

| クラス | 内容 | スーパークラス |
| --- | --- | --- |
| Window_Command | コマンドウィンドウ (汎用) | Window_Selectable |
| Window_HorzCommand | コマンドウィンドウ (横選択) | Window_Command |



これらのクラスは、いわゆるコマンドウィンドウの基本処理を 受け持っています。メニュー画面やバトル画面などに表示される各種の コマンドウィンドウはそれぞれ別個のクラスとして定義されていますが、 どれも Window_Command クラスをスーパークラスとしています。

Window_Command クラスは、前項で解説したハンドラの仕組みを応用し、 個々のコマンドにシンボルを関連付けるようになっています。 たとえば「アイテム」という名前のコマンドを :item というシンボルに 関連付けるには、add_command というメソッドを使って次のようにします。

```

 add_command("アイテム", :item)
```



add_command の 1 番目の引数にはコマンドの名前として表示する文字列、2 番目の引数には、そのコマンドに対応するシンボルを指定します。

この例の場合は、「アイテム」というコマンドを選択して決定が押された とき、:item に対応するハンドラが (set_handler メソッドによって) 設定 されていればそのメソッドを呼び出すように指定するということです。

ハンドラの実装を理解するのは少々大変ですが、まずは大まかな概念を 覚えておけば十分です。実践編にて、具体的な例を説明します。

## ウィンドウクラス一覧


残りのウィンドウ系のクラスを一気に紹介します。

| クラス | 使用画面 | 内容 | スーパークラス |
| --- | --- | --- | --- |
| Window_Help | 各種 | ヘルプウィンドウ | Window_Base |
| Window_Gold | メニュー、ショップ | 所持金表示ウィンドウ | Window_Base |
| Window_MenuCommand | メニュー | コマンドウィンドウ | Window_Command |
| Window_MenuStatus | メニュー | ステータスウィンドウ | Window_Selectable |
| Window_MenuActor | アイテム、スキル | 対象選択ウィンドウ | Window_MenuStatus |
| Window_ItemCategory | アイテム、ショップ | 分類選択ウィンドウ | Window_HorzCommand |
| Window_ItemList | アイテム | アイテム選択ウィンドウ | Window_Selectable |
| Window_SkillCommand | スキル | コマンドウィンドウ | Window_Command |
| Window_SkillStatus | スキル | ステータスウィンドウ | Window_Base |
| Window_SkillList | スキル | スキル選択ウィンドウ | Window_Selectable |
| Window_SkillStatus | スキル | ステータスウィンドウ | Window_Base |
| Window_EquipStatus | 装備 | ステータスウィンドウ | Window_Base |
| Window_EquipCommand | 装備 | コマンドウィンドウ | Window_HorzCommand |
| Window_EquipSlot | 装備 | 装備部位ウィンドウ | Window_Selectable |
| Window_EquipItem | 装備 | アイテムウィンドウ | Window_ItemList |
| Window_Status | ステータス | ステータスウィンドウ | Window_Base |
| Window_SaveFile | セーブ、ロード | ファイルウィンドウ | Window_Base |
| Window_ShopCommand | ショップ | コマンドウィンドウ | Window_HorzCommand |
| Window_ShopBuy | ショップ | 購入ウィンドウ | Window_Selectable |
| Window_ShopSell | ショップ | 売却ウィンドウ | Window_Item |
| Window_ShopNumber | ショップ | 個数入力ウィンドウ | Window_Base |
| Window_ShopStatus | ショップ | ステータスウィンドウ | Window_Base |
| Window_NameEdit | 名前入力 | 名前ウィンドウ | Window_Base |
| Window_NameInput | 名前入力 | 文字選択ウィンドウ | Window_Base |
| Window_ChoiceList | マップ | 選択肢ウィンドウ | Window_Command |
| Window_NumberInput | マップ | 数値入力ウィンドウ | Window_Base |
| Window_KeyItem | マップ | アイテム選択ウィンドウ | Window_ItemList |
| Window_Message | マップ | メッセージウィンドウ | Window_Selectable |
| Window_ScrollText | マップ | 文章のスクロール表示ウィンドウ | Window_Base |
| Window_BattleLog | バトル | ログウィンドウ | Window_Message |
| Window_PartyCommand | バトル | パーティコマンドウィンドウ | Window_Command |
| Window_ActorCommand | バトル | アクターコマンドウィンドウ | Window_Command |
| Window_BattleStatus | バトル | ステータスウィンドウ | Window_Selectable |
| Window_BattleActor | バトル | アクター選択ウィンドウ | Window_BattleStatus |
| Window_BattleEnemy | バトル | 敵キャラ選択ウィンドウ | Window_Command |
| Window_BattleSkill | バトル | スキル選択ウィンドウ | Window_SkillList |
| Window_BattleItem | バトル | アイテム選択ウィンドウ | Window_ItemList |
| Window_TitleCommand | タイトル | コマンドウィンドウ | Window_Command |
| Window_GameEnd | ゲーム終了 | コマンドウィンドウ | Window_Command |
| Window_DebugLeft | デバッグ | 左のウィンドウ | Window_Selectable |
| Window_DebugRight | デバッグ | 右のウィンドウ | Window_Selectable |



######
