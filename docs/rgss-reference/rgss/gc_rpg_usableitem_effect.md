# RPG::UsableItem::Effect


使用効果のデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::UsableItem](gc_rpg_usableitem.md)


## 属性



### code


使用効果コード。

### data_id


使用効果の種類に応じたデータ (ステート、能力値など) の ID。

### value1


使用効果の種類に応じた設定値 1。

### value2


使用効果の種類に応じた設定値 2。

## 定義


```

class RPG::UsableItem::Effect
 def initialize(code = 0, data_id = 0, value1 = 0, value2 = 0)
 @code = code
 @data_id = data_id
 @value1 = value1
 @value2 = value2
 end
 attr_accessor :code
 attr_accessor :data_id
 attr_accessor :value1
 attr_accessor :value2
end
```



######
