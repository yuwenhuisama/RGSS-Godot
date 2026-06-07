# ゲームオブジェクト


- [$game_xxxx](#game_xxxx)
- [ゲームオブジェクトの内容](#contents)
- [その他の関連クラス](#other)


データベースは、原則としてゲーム中に書き換わることがない 不変のデータです。それに対して、たとえばマップ画面上を動き回る キャラクターなど、その状態が刻々と変わっていくようなデータを 扱うのが**ゲームオブジェクト**です。

## $game_xxxx


DataManager セクションの中ほどに、create_game_objects というメソッドが あります。これも、データベースの作成と同じタイミングで呼び出される メソッドです。

```

 def self.create_game_objects
 $game_temp = Game_Temp.new
 $game_system = Game_System.new
 $game_timer = Game_Timer.new
 $game_message = Game_Message.new
 $game_switches = Game_Switches.new
 $game_variables = Game_Variables.new
 $game_self_switches = Game_SelfSwitches.new
 $game_actors = Game_Actors.new
 $game_party = Game_Party.new
 $game_troop = Game_Troop.new
 $game_map = Game_Map.new
 $game_player = Game_Player.new
 end
```



データベースの $data_xxxx 系と同じように、これらも また**グローバル変数**です。Game_Xxxx という名前の クラスのインスタンスを作成し、これらの変数で参照できるようにして います。この Game_Xxxx という名前には見覚えがありますね。スクリプト エディタで、上のほうのセクションにこのような名前がついています。 つまり、これらのセクションで定義されたクラスを、ここで実体化して いるというわけです。

クラスの名前に .new をつけると「そのクラスのインスタンスを生成する」 という意味になります。インスタンスとは何かを忘れてしまった方は、[オブジェクト](108_object.md)の復習をしてください。

## ゲームオブジェクトの内容


各オブジェクトは次の表のようになっています。データベースの場合と 異なり、これらのオブジェクトが所属するクラスは RGSS にあらかじめ組み 込まれているわけではなく、スクリプトエディタの中で定義されています。

| 変数名 | 内容 | クラス |
| --- | --- | --- |
| $game_temp | 一時データ | Game_Temp |
| $game_system | システムデータ | Game_System |
| $game_timer | タイマー | Game_Timer |
| $game_message | メッセージ | Game_Message |
| $game_switches | スイッチ | Game_Switches |
| $game_variables | 変数 | Game_Variables |
| $game_self_switches | セルフスイッチ | Game_SelfSwitches |
| $game_actors | アクターリスト | Game_Actors |
| $game_party | パーティ | Game_Party |
| $game_troop | 敵グループ | Game_Troop |
| $game_map | マップ | Game_Map |
| $game_player | プレイヤー | Game_Player |



これらのクラスは原則としてデータ構造を提供するだけで、グラフィックを 表示したりボタン入力を受け付けたりする機能は持っていません。 ただし Game_Player クラスだけは便宜上、方向ボタンによる移動や決定ボタン によるイベント起動などの処理を含んでいます。

## その他の関連クラス


グローバル変数から直接アクセスできるゲームオブジェクトは前述のもの だけですが、これらのオブジェクトの内部には、さらに別のゲームオブジェク トが含まれています。それらを以下の表に示します。

| クラス | 内容 | 説明 |
| --- | --- | --- |
| Game_Screen | 画面効果 | Game_Map、Game_Troop の内部で使用 |
| Game_Picture | ピクチャ | Game_Pictures の内部で使用 |
| Game_Pictures | ピクチャリスト | Game_Screen の内部で使用 |
| Game_BaseItem | アイテムなど | Game_Action、Game_Actor、Game_Party の内部で使用 |
| Game_Action | 戦闘行動 | Game_Battler、Game_Actor の内部で使用 |
| Game_ActionResult | 戦闘行動の結果 | Game_Battler の内部で使用 |
| Game_Actor | アクター | Game_Actors の内部で使用 |
| Game_Enemy | 敵キャラ | Game_Troop の内部で使用 |
| Game_CommonEvent | コモンイベント | Game_Map の内部で使用 |
| Game_Follower | フォロワー (隊列歩行) | Game_Followers の内部で使用 |
| Game_Followers | フォロワーリスト | Game_Player の内部で使用 |
| Game_Vehicle | 乗り物 | Game_Map の内部で使用 |
| Game_Event | マップイベント | Game_Map の内部で使用 |
| Game_Interpreter | インタプリタ | Game_Map、Game_Troop、Game_Event の内部で使用 |



さらに、重要なクラスとして以下のものがあります。

| クラス | 内容 | 説明 |
| --- | --- | --- |
| Game_BattlerBase | バトラー (基本) | Game_Battler のスーパークラス |
| Game_Battler | バトラー | Game_Actor、Game_Enemy のスーパークラス |
| Game_Unit | ユニット | Game_Party、Game_Troop のスーパークラス |
| Game_CharacterBase | キャラクター (基本) | Game_Character のスーパークラス |
| Game_Character | キャラクター | Game_Player、Game_Event のスーパークラス |



スーパークラスというのは、クラスを**継承**される 側のことでした。アクターと敵キャラ、パーティと敵グループ、 プレイヤーとイベントにはそれぞれ共通の性質がありますから、その 共通部分をひとつのクラスにまとめているというわけです。

この「スクリプト入門」はプリセットのスクリプトの大まかな全体像を 把握することが目的なので、この章で取り上げたクラスの内容を個々に解説する ことまではできません。しかし、実際にスクリプトの改造に挑戦する際には、 これらがどのような定義になっているかということはとても重要になって きます。

解読の基本的な考え方は、Vocab、Sound、Cache モジュールで解説したのと 同様です。最初のうちはよくわからなくても、興味のあるところを眺めてみる ことをお勧めします。

######
