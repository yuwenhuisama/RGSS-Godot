# RPG::Map::Encounter


エンカウント設定のデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::Map](gc_rpg_troop.md)


## 属性



### troop_id


敵グループ ID。

### weight


重み。

### region_set


リージョン ID を格納した配列。

## 定義


```

class RPG::Map::Encounter
 def initialize
 @troop_id = 1
 @weight = 10
 @region_set = []
 end
 attr_accessor :troop_id
 attr_accessor :weight
 attr_accessor :region_set
end
```



######
