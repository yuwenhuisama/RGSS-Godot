# RPG::Troop::Member


敵グループメンバーのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::Troop](gc_rpg_troop.md)


## 属性



### enemy_id


敵キャラ ID。

### x


足元の X 座標。

### y


足元の Y 座標。

### hidden


オプション [途中から出現] の真偽値。

## 定義


```

class RPG::Troop::Member
 def initialize
 @enemy_id = 1
 @x = 0
 @y = 0
 @hidden = false
 end
 attr_accessor :enemy_id
 attr_accessor :x
 attr_accessor :y
 attr_accessor :hidden
end
```



######
