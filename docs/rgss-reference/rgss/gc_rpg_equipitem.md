# RPG::EquipItem


武器と防具のスーパークラス。

## スーパークラス


- [RPG::BaseItem](gc_rpg_baseitem.md)


## 属性



### price


価格。

### etype_id


装備タイプ。

- 0 : 武器
- 1 : 盾
- 2 : 頭
- 3 : 身体
- 4 : 装飾品


### params


能力値変化量。以下の ID を添字とする整数の配列です。

- 0 : 最大HP
- 1 : 最大MP
- 2 : 攻撃力
- 3 : 防御力
- 4 : 魔法力
- 5 : 魔法防御
- 6 : 敏捷性
- 7 : 運


## 定義


```

class RPG::EquipItem < RPG::BaseItem
 def initialize
 super
 @price = 0
 @etype_id = 0
 @params = [0] * 8
 end
 attr_accessor :price
 attr_accessor :etype_id
 attr_accessor :params
end
```



######
