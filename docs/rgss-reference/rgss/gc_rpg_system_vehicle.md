# RPG::System::Vehicle


乗り物のデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::System](gc_rpg_system.md)


## 属性



### character_name


歩行グラフィックのファイル名。

### character_index


歩行グラフィックのインデックス (0..7) 。

### bgm


BGM ([RPG::BGM](gc_rpg_bgm.md)) 。

### start_map_id


初期位置のマップ ID。

### start_x


初期位置のマップ X 座標。

### start_y


初期位置のマップ Y 座標。

## 定義


```

class RPG::System::Vehicle
 def initialize
 @character_name = ''
 @character_index = 0
 @bgm = RPG::BGM.new
 @start_map_id = 0
 @start_x = 0
 @start_y = 0
 end
 attr_accessor :character_name
 attr_accessor :character_index
 attr_accessor :bgm
 attr_accessor :start_map_id
 attr_accessor :start_x
 attr_accessor :start_y
end
```



######
