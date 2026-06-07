# RPG::Item


アイテムのデータクラス。

## スーパークラス


- [RPG::UsableItem](gc_rpg_usableitem.md)


## 属性



### itype_id


アイテムタイプ ID。

- 1 : 通常
- 2 : 大事なもの


### price


価格。

### consumable


消耗するかどうかの真偽値。

## メソッド



### key_item?



アイテムタイプが［大事なもの］か否かを判定します。itype_id の値が 2 のときに真を返します。

## 定義


```

class RPG::Item < RPG::UsableItem
 def initialize
 super
 @scope = 7
 @itype_id = 1
 @price = 0
 @consumable = true
 end
 def key_item?
 @itype_id == 2
 end
 attr_accessor :itype_id
 attr_accessor :price
 attr_accessor :consumable
end
```



######
