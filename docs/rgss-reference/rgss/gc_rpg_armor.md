# RPG::Armor


防具のデータクラス。

## スーパークラス


- [RPG::EquipItem](gc_rpg_baseitem.md)


## 属性



### atype_id


防具タイプ ID。

## メソッド



### performance



防具としての性能を評価します。最強装備コマンドで使用されます。

防御力 + 魔法防御 + 全能力値の合計を返します。

## 定義


```

class RPG::Armor < RPG::EquipItem
 def initialize
 super
 @atype_id = 0
 @etype_id = 1
 @features.push(RPG::BaseItem::Feature.new(22, 1, 0))
 end
 def performance
 params[3] + params[5] + params.inject(0) {|r, v| r += v }
 end
 attr_accessor :atype_id
end
```



######
