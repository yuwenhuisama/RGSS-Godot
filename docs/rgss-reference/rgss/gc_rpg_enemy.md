# RPG::Enemy


敵キャラのデータクラス。

## スーパークラス


- [RPG::BaseItem](gc_rpg_baseitem.md)


## 属性



### battler_name


戦闘グラフィックのファイル名。

### battler_hue


戦闘グラフィックの色相変化値 (0..360) 。

### params


能力値。以下の ID を添字とする整数の配列です。

- 0 : 最大HP
- 1 : 最大MP
- 2 : 攻撃力
- 3 : 防御力
- 4 : 魔法力
- 5 : 魔法防御
- 6 : 敏捷性
- 7 : 運


### exp


経験値。

### gold


お金。

### drop_items


ドロップアイテム。[RPG::Enemy::DropItem](gc_rpg_enemy_drop_item.md) の配列です。

### actions


行動パターン。[RPG::Enemy::Action](gc_rpg_enemy_action.md) の配列です。

## 内部クラス


- [RPG::Enemy::DropItem](gc_rpg_enemy_drop_item.md)
- [RPG::Enemy::Action](gc_rpg_enemy_action.md)


## 定義


```

class RPG::Enemy < RPG::BaseItem
 def initialize
 super
 @battler_name = ''
 @battler_hue = 0
 @params = [100,0,10,10,10,10,10,10]
 @exp = 0
 @gold = 0
 @drop_items = Array.new(3) { RPG::Enemy::DropItem.new }
 @actions = [RPG::Enemy::Action.new]
 @features.push(RPG::BaseItem::Feature.new(22, 0, 0.95))
 @features.push(RPG::BaseItem::Feature.new(22, 1, 0.05))
 @features.push(RPG::BaseItem::Feature.new(31, 1, 0))
 end
 attr_accessor :battler_name
 attr_accessor :battler_hue
 attr_accessor :params
 attr_accessor :exp
 attr_accessor :gold
 attr_accessor :drop_items
 attr_accessor :actions
end
```



######
