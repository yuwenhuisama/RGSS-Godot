# RPG::Enemy::DropItem


敵キャラの [ドロップアイテム] のデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::Enemy](gc_rpg_enemy.md)


## 属性



### kind


種類。

- 0 : なし
- 1 : アイテム
- 2 : 武器
- 3 : 防具


### data_id


ドロップアイテムの種類に応じたデータ (アイテム、武器、防具) の ID。

### denominator


出現率 1/N の分母 N。

## 定義


```

class RPG::Enemy::DropItem
 def initialize
 @kind = 0
 @data_id = 1
 @denominator = 1
 end
 attr_accessor :kind
 attr_accessor :data_id
 attr_accessor :denominator
end
```



######
