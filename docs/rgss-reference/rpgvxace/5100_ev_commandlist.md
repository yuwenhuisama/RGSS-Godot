# イベントコマンドの機能解説


イベントの［実行内容］で使用できるイベントコマンドには、以下のものが用意されています。これらを上手に使って、作品のストーリーを演出しましょう。



●タブ1

| **▼メッセージ** | **▼パーティ** |
| --- | --- |
| [文章の表示](5110_ev_ref_message.md#message01) | [所持金の増減](5140_ev_ref_party.md#party01) |
| [選択肢の表示](5110_ev_ref_message.md#message02) | [アイテムの増減](5140_ev_ref_party.md#party02) |
| [数値入力の処理](5110_ev_ref_message.md#message03) | [武器の増減](5140_ev_ref_party.md#party03) |
| [アイテム選択の処理](5110_ev_ref_message.md#message04) | [防具の増減](5140_ev_ref_party.md#party04) |
| [文章のスクロール表示](5110_ev_ref_message.md#message05) | [メンバーの入れ替え](5140_ev_ref_party.md#party05) |
| **▼ゲーム進行** | **▼アクター** |
| [スイッチの操作](5120_ev_ref_progress.md#progress01) | [HPの増減](5150_ev_ref_actor.md#actor01) |
| [変数の操作](5120_ev_ref_progress.md#progress02) | [MPの増減](5150_ev_ref_actor.md#actor02) |
| [セルフスイッチの操作](5120_ev_ref_progress.md#progress03) | [ステートの変更](5150_ev_ref_actor.md#actor03) |
| [タイマーの操作](5120_ev_ref_progress.md#progress04) | [全回復](5150_ev_ref_actor.md#actor04) |
| **▼フロー制御** | [経験値の増減](5150_ev_ref_actor.md#actor05) |
| [条件分岐](5130_ev_ref_flow.md#flow01) | [レベルの増減](5150_ev_ref_actor.md#actor06) |
| [ループ](5130_ev_ref_flow.md#flow02) | [能力値の増減](5150_ev_ref_actor.md#actor07) |
| [ループの中断](5130_ev_ref_flow.md#flow03) | [スキルの増減](5150_ev_ref_actor.md#actor08) |
| [イベント処理の中断](5130_ev_ref_flow.md#flow04) | [装備の変更](5150_ev_ref_actor.md#actor09) |
| [コモンイベント](5130_ev_ref_flow.md#flow05) | [名前の変更](5150_ev_ref_actor.md#actor10) |
| [ラベル](5130_ev_ref_flow.md#flow06) | [職業の変更](5150_ev_ref_actor.md#actor11) |
| [ラベルジャンプ](5130_ev_ref_flow.md#flow07) | [二つ名の変更](5150_ev_ref_actor.md#actor12) |
| [注釈](5130_ev_ref_flow.md#flow08) | |





●タブ2

| **▼移動** | **▼時間調整** |
| --- | --- |
| [場所移動](5210_ev_ref_move.md#move01) | [ウェイト](5240_ev_ref_wait.md#wait01) |
| [乗り物の位置設定](5210_ev_ref_move.md#move02) | **▼ピクチャと天候** |
| [イベントの位置設定](5210_ev_ref_move.md#move03) | [ピクチャの表示](5250_ev_ref_picture.md#picture01) |
| [マップのスクロール](5210_ev_ref_move.md#move04) | [ピクチャの移動](5250_ev_ref_picture.md#picture02) |
| [移動ルートの設定](5210_ev_ref_move.md#move05) | [ピクチャの回転](5250_ev_ref_picture.md#picture03) |
| [乗り物の乗降](5210_ev_ref_move.md#move06) | [ピクチャの色調変更](5250_ev_ref_picture.md#picture04) |
| **▼キャラクター** | [ピクチャの消去](5250_ev_ref_picture.md#picture05) |
| [透明状態の変更](5220_ev_ref_character.md#character01) | [天候の設定](5250_ev_ref_picture.md#picture06) |
| [隊列歩行の変更](5220_ev_ref_character.md#character02) | **▼音楽と効果音** |
| [隊列メンバーの集合](5220_ev_ref_character.md#character03) | [BGMの演奏](5260_ev_ref_bgmse.md#bgmse01) |
| [アニメーションの表示](5220_ev_ref_character.md#character04) | [BGMのフェードアウト](5260_ev_ref_bgmse.md#bgmse02) |
| [フキダシアイコンの表示](5220_ev_ref_character.md#character05) | [BGMの保存](5260_ev_ref_bgmse.md#bgmse03) |
| [イベントの一時消去](5220_ev_ref_character.md#character06) | [BGMの再開](5260_ev_ref_bgmse.md#bgmse04) |
| **▼画面効果** | [BGSの演奏](5260_ev_ref_bgmse.md#bgmse05) |
| [画面のフェードアウト](5230_ev_ref_screen.md#screen01) | [BGSのフェードアウト](5260_ev_ref_bgmse.md#bgmse06) |
| [画面のフェードイン](5230_ev_ref_screen.md#screen02) | [MEの演奏](5260_ev_ref_bgmse.md#bgmse07) |
| [画面の色調変更](5230_ev_ref_screen.md#screen03) | [SEの演奏](5260_ev_ref_bgmse.md#bgmse08) |
| [画面のフラッシュ](5230_ev_ref_screen.md#screen04) | [SEの停止](5260_ev_ref_bgmse.md#bgmse09) |
| [画面のシェイク](5230_ev_ref_screen.md#screen05) | |





●タブ3

| **▼シーン制御** | **▼マップ** |
| --- | --- |
| [バトルの処理](5310_ev_ref_scene.md#scene01) | [マップ名表示の変更](5340_ev_ref_map.md#map01) |
| [ショップの処理](5310_ev_ref_scene.md#scene02) | [タイルセットの変更](5340_ev_ref_map.md#map02) |
| [名前入力の処理](5310_ev_ref_scene.md#scene03) | [戦闘背景の変更](5340_ev_ref_map.md#map03) |
| [メニュー画面を開く](5310_ev_ref_scene.md#scene04) | [遠景の変更](5340_ev_ref_map.md#map04) |
| [セーブ画面を開く](5310_ev_ref_scene.md#scene05) | [指定位置の情報取得](5340_ev_ref_map.md#map05) |
| [ゲームオーバー](5310_ev_ref_scene.md#scene06) | **▼バトル** |
| [タイトル画面に戻す](5310_ev_ref_scene.md#scene07) | [敵キャラのHP増減](5350_ev_ref_battle.md#battle01) |
| **▼システム設定** | [敵キャラのMP増減](5350_ev_ref_battle.md#battle02) |
| [戦闘BGMの変更](5320_ev_ref_system.md#system01) | [敵キャラのステート変更](5350_ev_ref_battle.md#battle03) |
| [戦闘終了MEの変更](5320_ev_ref_system.md#system02) | [敵キャラの全回復](5350_ev_ref_battle.md#battle04) |
| [セーブ禁止の変更](5320_ev_ref_system.md#system03) | [敵キャラの出現](5350_ev_ref_battle.md#battle05) |
| [メニュー禁止の変更](5320_ev_ref_system.md#system04) | [敵キャラの変身](5350_ev_ref_battle.md#battle06) |
| [エンカウント禁止の変更](5320_ev_ref_system.md#system05) | [戦闘アニメーションの表示](5350_ev_ref_battle.md#battle07) |
| [並び替え禁止の変更](5320_ev_ref_system.md#system06) | [戦闘行動の強制](5350_ev_ref_battle.md#battle08) |
| [ウィンドウカラーの変更](5320_ev_ref_system.md#system07) | [バトルの中断](5350_ev_ref_battle.md#battle09) |
| [アクターのグラフィック変更](5320_ev_ref_system.md#system08) | **▼上級** |
| [乗り物のグラフィック変更](5320_ev_ref_system.md#system09) | [スクリプト](5360_ev_ref_highclass.md#highclass01) |
| [ムービーの再生](5330_ev_ref_movie.md#movie01) | |



######
