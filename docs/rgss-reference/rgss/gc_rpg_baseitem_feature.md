# RPG::BaseItem::Feature


特徴のデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::BaseItem](gc_rpg_baseitem.md)


## 属性



### code


特徴コード。

### data_id


特徴の種類に応じたデータ (属性、ステートなど) の ID。

### value


特徴の種類に応じた設定値。

## 定義


```

class RPG::BaseItem::Feature
 def initialize(code = 0, data_id = 0, value = 0)
 @code = code
 @data_id = data_id
 @value = value
 end
 attr_accessor :code
 attr_accessor :data_id
 attr_accessor :value
end
```



######
