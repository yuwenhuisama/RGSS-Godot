# RPG::Weapon


武器のデータクラス。

## スーパークラス


- [RPG::EquipItem](gc_rpg_baseitem.md)


## 属性



### wtype_id


武器タイプ ID。

### animation_id


アニメーション ID。

## メソッド



### performance



武器としての性能を評価します。最強装備コマンドで使用されます。

攻撃力 + 魔法力 + 全能力値の合計を返します。

## 定義


```

class RPG::Weapon < RPG::EquipItem
 def initialize
 super
 @wtype_id = 0
 @animation_id = 0
 @features.push(RPG::BaseItem::Feature.new(31, 1, 0))
 @features.push(RPG::BaseItem::Feature.new(22, 0, 0))
 end
 def performance
 params[2] + params[4] + params.inject(0) {|r, v| r += v }
 end
 attr_accessor :wtype_id
 attr_accessor :animation_id
end
```



######
