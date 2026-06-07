# RPG::Actor


アクターのデータクラス。

## スーパークラス


- [RPG::BaseItem](gc_rpg_baseitem.md)


## 属性



### nickname


二つ名。

### class_id


職業 ID。

### initial_level


初期レベル。

### max_level


最高レベル。

### character_name


歩行グラフィックのファイル名。

### character_index


歩行グラフィックのインデックス (0..7) 。

### face_name


顔グラフィックのファイル名。

### face_index


顔グラフィックのインデックス (0..7) 。

### equips


初期装備。以下を添字とする、武器 ID または防具 ID の配列です。

- 0 : 武器
- 1 : 盾
- 2 : 頭
- 3 : 身体
- 4 : 装飾品


## 定義


```

class RPG::Actor < RPG::BaseItem
 def initialize
 super
 @nickname = ''
 @class_id = 1
 @initial_level = 1
 @max_level = 99
 @character_name = ''
 @character_index = 0
 @face_name = ''
 @face_index = 0
 @equips = [0,0,0,0,0]
 end
 attr_accessor :nickname
 attr_accessor :class_id
 attr_accessor :initial_level
 attr_accessor :max_level
 attr_accessor :character_name
 attr_accessor :character_index
 attr_accessor :face_name
 attr_accessor :face_index
 attr_accessor :equips
end
```



######
