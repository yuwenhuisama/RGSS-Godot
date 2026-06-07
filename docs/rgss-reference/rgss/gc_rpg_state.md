# RPG::State


ステートのデータクラス。

## スーパークラス


- [RPG::BaseItem](gc_rpg_baseitem.md)


## 属性



### restriction


行動制約。

- 0 : なし
- 1 : 敵を攻撃する
- 2 : 敵か味方を攻撃する
- 3 : 味方を攻撃する
- 4 : 行動できない


### priority


表示優先度 (0..100) 。

### remove_at_battle_end


戦闘終了時に解除 (true / false) 。

### remove_by_restriction


行動制約によって解除 (true / false) 。

### auto_removal_timing


自動解除のタイミング。

- 0 : なし
- 1 : 行動終了時
- 2 : ターン終了時


### min_turns


### max_turns


継続ターン数の最小値と最大値。

### remove_by_damage


ダメージで解除 (true / false) 。

### chance_by_damage


ダメージで解除される確率 (%) 。

### remove_by_walking


歩数で解除 (true / false) 。

### steps_to_remove


解除されるまでの歩数。

### message1


### message2


### message3


### message4


メッセージ。上から、味方、敵、継続、解除。

## 定義


```

class RPG::State < RPG::BaseItem
 def initialize
 super
 @restriction = 0
 @priority = 50
 @remove_at_battle_end = false
 @remove_by_restriction = false
 @auto_removal_timing = 0
 @min_turns = 1
 @max_turns = 1
 @remove_by_damage = false
 @chance_by_damage = 100
 @remove_by_walking = false
 @steps_to_remove = 100
 @message1 = ''
 @message2 = ''
 @message3 = ''
 @message4 = ''
 end
 attr_accessor :restriction
 attr_accessor :priority
 attr_accessor :remove_at_battle_end
 attr_accessor :remove_by_restriction
 attr_accessor :auto_removal_timing
 attr_accessor :min_turns
 attr_accessor :max_turns
 attr_accessor :remove_by_damage
 attr_accessor :chance_by_damage
 attr_accessor :remove_by_walking
 attr_accessor :steps_to_remove
 attr_accessor :message1
 attr_accessor :message2
 attr_accessor :message3
 attr_accessor :message4
end
```



######
