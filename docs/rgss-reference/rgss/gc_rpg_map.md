# RPG::Map


マップのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 属性



### display_name


マップの表示名。

### tileset_id


マップで使用するタイルセットの ID。

### width


マップの幅。

### height


マップの高さ。

### scroll_type


スクロールタイプ (0: ループしない、1:縦のみ ループする、2:横のみループする、3:縦横ともループする)。

### specify_battleback


戦闘背景指定が有効かどうかを示す真偽値。

### battleback1_name


戦闘背景指定が有効なとき、床グラフィックのファイル名。

### battleback2_name


戦闘背景指定が有効なとき、壁グラフィックのファイル名。

### autoplay_bgm


BGM 自動切り替えが有効かどうかを示す真偽値。

### bgm


BGM 自動切り替えが有効なとき、その BGM ([RPG::BGM](gc_rpg_bgm.md)) 。

### autoplay_bgs


BGS 自動切り替えが有効かどうかを示す真偽値。

### bgs


BGS 自動切り替えが有効なとき、その BGS ([RPG::BGS](gc_rpg_bgs.md)) 。

### disable_dashing


[ダッシュを禁止する] オプションの真偽値。

### encounter_list


エンカウントリスト。[RPG::Map::Encounter](gc_rpg_map_encounter.md) の配列です。

### encounter_step


平均エンカウント歩数。

### parallax_name


遠景グラフィックのファイル名。

### parallax_loop_x


遠景の [横方向ループ] オプションの真偽値。

### parallax_loop_y


遠景の [縦方向ループ] オプションの真偽値。

### parallax_sx


遠景が横方向に自動スクロールする速度。

### parallax_sy


遠景が縦方向に自動スクロールする速度。

### parallax_show


遠景の [マップエディタに表示する] オプションの真偽値。

### note


メモ。

### data


マップデータ本体。タイル ID および付随するデータの 三次元配列 ([Table](gc_table.md)) です。

### events


マップイベント。イベント ID を キー、[RPG::Event](gc_rpg_event.md) のインスタンスを値とするハッシュです。

## 内部クラス


- [RPG::Map::Encounter](gc_rpg_map_encounter.md)


## 定義


```

class RPG::Map
 def initialize(width, height)
 @display_name = ''
 @tileset_id = 1
 @width = width
 @height = height
 @scroll_type = 0
 @specify_battleback = false
 @battleback_floor_name = ''
 @battleback_wall_name = ''
 @autoplay_bgm = false
 @bgm = RPG::BGM.new
 @autoplay_bgs = false
 @bgs = RPG::BGS.new('', 80)
 @disable_dashing = false
 @encounter_list = []
 @encounter_step = 30
 @parallax_name = ''
 @parallax_loop_x = false
 @parallax_loop_y = false
 @parallax_sx = 0
 @parallax_sy = 0
 @parallax_show = false
 @note = ''
 @data = Table.new(width, height, 4)
 @events = {}
 end
 attr_accessor :display_name
 attr_accessor :tileset_id
 attr_accessor :width
 attr_accessor :height
 attr_accessor :scroll_type
 attr_accessor :specify_battleback
 attr_accessor :battleback1_name
 attr_accessor :battleback2_name
 attr_accessor :autoplay_bgm
 attr_accessor :bgm
 attr_accessor :autoplay_bgs
 attr_accessor :bgs
 attr_accessor :disable_dashing
 attr_accessor :encounter_list
 attr_accessor :encounter_step
 attr_accessor :parallax_name
 attr_accessor :parallax_loop_x
 attr_accessor :parallax_loop_y
 attr_accessor :parallax_sx
 attr_accessor :parallax_sy
 attr_accessor :parallax_show
 attr_accessor :note
 attr_accessor :data
 attr_accessor :events
end
```



######
