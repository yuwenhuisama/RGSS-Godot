# RPG::System


システムのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 属性



### game_title


ゲームタイトル。

### version_id


更新チェック用の乱数。 ツクールでデータを保存するたびに異なる値に書き換えられます。

### japanese


日本語版では常に true になります。

### party_members


初期パーティ。アクター ID の配列です。

### currency_unit


通貨単位。

### window_tone


ウィンドウカラー ([Tone](gc_tone.md))。

### elements


属性名のリスト。属性 ID を 添字に取る文字列の配列で、0 番目の要素は nil です。

### skill_types


スキルタイプ名のリスト。スキルタイプ ID を 添字に取る文字列の配列で、0 番目の要素は nil です。

### weapon_types


武器タイプ名のリスト。武器タイプ ID を 添字に取る文字列の配列で、0 番目の要素は nil です。

### armor_types


防具タイプ名のリスト。防具タイプ ID を 添字に取る文字列の配列で、0 番目の要素は nil です。

### switches


スイッチ名のリスト。スイッチ ID を 添字に取る文字列の配列で、0 番目の要素は nil です。

### variables


変数名のリスト。変数 ID を 添字に取る文字列の配列で、0 番目の要素は nil です。

### boat


小型船の設定 ([RPG::System::Vehicle](gc_rpg_system_vehicle.md)) 。

### ship


大型船の設定 ([RPG::System::Vehicle](gc_rpg_system_vehicle.md)) 。

### airship


飛行船の設定 ([RPG::System::Vehicle](gc_rpg_system_vehicle.md)) 。

### title1_name


タイトル（背景）グラフィックのファイル名。

### title2_name


タイトル（枠）グラフィックのファイル名。

### opt_draw_title


オプション［ゲームタイトルの描画］の真偽値。

### opt_use_midi


オプション［起動時に MIDI を初期化］の真偽値。

### opt_transparent


オプション［透明状態で開始］の真偽値。

### opt_followers


オプション［パーティの隊列歩行］の真偽値。

### opt_slip_death


オプション［スリップダメージで戦闘不能］の真偽値。

### opt_floor_death


オプション［床ダメージで戦闘不能］の真偽値。

### opt_display_tp


オプション［バトル画面で TP を表示］の真偽値。

### opt_extra_exp


オプション［控えメンバーも経験値を獲得］の真偽値。

### title_bgm


タイトル BGM ([RPG::BGM](gc_rpg_bgm.md)) 。

### battle_bgm


戦闘 BGM ([RPG::BGM](gc_rpg_bgm.md)) 。

### battle_end_me


戦闘終了 ME ([RPG::ME](gc_rpg_me.md)) 。

### gameover_me


ゲームオーバー ME ([RPG::ME](gc_rpg_me.md)) 。

### sounds


効果音。[RPG::SE](gc_rpg_se.md) の配列です。

### start_map_id


プレイヤーの初期位置の、マップ ID。

### start_x


プレイヤーの初期位置の、マップ X 座標。

### start_y


プレイヤーの初期位置の、マップ Y 座標。

### terms


用語 ([RPG::System::Terms](gc_rpg_system_terms.md)) 。

### test_battlers


戦闘テストのパーティ設定。[RPG::System::TestBattler](gc_rpg_system_testbattler.md) の配列です。

### test_troop_id


戦闘テストの敵グループ ID。

### battleback1_name


敵グループの編集および戦闘テストで 使用する、戦闘背景（床）グラフィックのファイル名。

### battleback2_name


敵グループの編集および戦闘テストで 使用する、戦闘背景（壁）グラフィックのファイル名。

### battler_name


アニメーションの編集で 使用する、戦闘グラフィックのファイル名。

### battler_hue


アニメーションの編集で 使用する、戦闘グラフィックの色相変化値 (0..360) 。

### edit_map_id


内部用。現在編集しているマップの ID。

## 内部クラス


- [RPG::System::Vehicle](gc_rpg_system_vehicle.md)
- [RPG::System::Terms](gc_rpg_system_terms.md)
- [RPG::System::TestBattler](gc_rpg_system_testbattler.md)


## 定義


```

class RPG::System
 def initialize
 @game_title = ''
 @version_id = 0
 @japanese = true
 @party_members = [1]
 @currency_unit = ''
 @elements = [nil, '']
 @skill_types = [nil, '']
 @weapon_types = [nil, '']
 @armor_types = [nil, '']
 @switches = [nil, '']
 @variables = [nil, '']
 @boat = RPG::System::Vehicle.new
 @ship = RPG::System::Vehicle.new
 @airship = RPG::System::Vehicle.new
 @title1_name = ''
 @title2_name = ''
 @opt_draw_title = true
 @opt_use_midi = false
 @opt_transparent = false
 @opt_followers = true
 @opt_slip_death = false
 @opt_floor_death = false
 @opt_display_tp = true
 @opt_extra_exp = false
 @window_tone = Tone.new(0,0,0)
 @title_bgm = RPG::BGM.new
 @battle_bgm = RPG::BGM.new
 @battle_end_me = RPG::ME.new
 @gameover_me = RPG::ME.new
 @sounds = Array.new(24) { RPG::SE.new }
 @test_battlers = []
 @test_troop_id = 1
 @start_map_id = 1
 @start_x = 0
 @start_y = 0
 @terms = RPG::System::Terms.new
 @battleback1_name = ''
 @battleback2_name = ''
 @battler_name = ''
 @battler_hue = 0
 @edit_map_id = 1
 end
 attr_accessor :game_title
 attr_accessor :version_id
 attr_accessor :japanese
 attr_accessor :party_members
 attr_accessor :currency_unit
 attr_accessor :skill_types
 attr_accessor :weapon_types
 attr_accessor :armor_types
 attr_accessor :elements
 attr_accessor :switches
 attr_accessor :variables
 attr_accessor :boat
 attr_accessor :ship
 attr_accessor :airship
 attr_accessor :title1_name
 attr_accessor :title2_name
 attr_accessor :opt_draw_title
 attr_accessor :opt_use_midi
 attr_accessor :opt_transparent
 attr_accessor :opt_followers
 attr_accessor :opt_slip_death
 attr_accessor :opt_floor_death
 attr_accessor :opt_display_tp
 attr_accessor :opt_extra_exp
 attr_accessor :window_tone
 attr_accessor :title_bgm
 attr_accessor :battle_bgm
 attr_accessor :battle_end_me
 attr_accessor :gameover_me
 attr_accessor :sounds
 attr_accessor :test_battlers
 attr_accessor :test_troop_id
 attr_accessor :start_map_id
 attr_accessor :start_x
 attr_accessor :start_y
 attr_accessor :terms
 attr_accessor :battleback1_name
 attr_accessor :battleback2_name
 attr_accessor :battler_name
 attr_accessor :battler_hue
 attr_accessor :edit_map_id
end
```



######
