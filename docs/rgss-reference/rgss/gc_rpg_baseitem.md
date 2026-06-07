# RPG::BaseItem


アクター、職業、スキル、アイテム、武器、防具、敵キャラ、およびステートのスーパークラス。

データの種類によっては一部不要な項目もありますが、それらは便宜上含まれているものです。

## スーパークラス


- [Object](sc_object.md)


## 属性



### id


ID。

### name


名前。

### icon_index


アイコン番号。

### description


説明。

### features


特徴リスト。[RPG::BaseItem::Feature](gc_rpg_baseitem_feature.md) の配列です。

### note


メモ。

## 内部クラス


- [RPG::BaseItem::Feature](gc_rpg_baseitem_feature.md)


## 定義


```

class RPG::BaseItem
 def initialize
 @id = 0
 @name = ''
 @icon_index = 0
 @description = ''
 @features = []
 @note = ''
 end
 attr_accessor :id
 attr_accessor :name
 attr_accessor :icon_index
 attr_accessor :description
 attr_accessor :features
 attr_accessor :note
end
```



######
