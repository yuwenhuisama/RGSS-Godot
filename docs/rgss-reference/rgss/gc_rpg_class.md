# RPG::Class


職業のデータクラス。

## スーパークラス


- [RPG::BaseItem](gc_rpg_baseitem.md)


## 属性



### exp_params


経験値曲線を決定する数値の配列。添字は以下の通りです。

- 0 : 基本値
- 1 : 補正値
- 2 : 増加度 A
- 3 : 増加度 B


### params


能力値成長曲線。各レベルに対応する通常能力値を格納した二次元配列 ([Table](gc_table.md)) です。

params[*param_id*, *level*] という形をとり、*param_id* は以下の割り当てになります。

- 0 : 最大HP
- 1 : 最大MP
- 2 : 攻撃力
- 3 : 防御力
- 4 : 魔法力
- 5 : 魔法防御
- 6 : 敏捷性
- 7 : 運


### learnings


習得するスキル。[RPG::Class::Learning](gc_rpg_class_learning.md) の配列です。

## メソッド



### exp_for_level(*level*)



*level* に上がるのに必要な累計経験値を計算して返します。

## 内部クラス


- [RPG::Class::Learning](gc_rpg_class_learning.md)


## 定義


```

class RPG::Class < RPG::BaseItem
 def initialize
 super
 @exp_params = [30,20,30,30]
 @params = Table.new(8,100)
 (1..99).each do |i|
 @params[0,i] = 400+i*50
 @params[1,i] = 80+i*10
 (2..5).each {|j| @params[j,i] = 15+i*5/4 }
 (6..7).each {|j| @params[j,i] = 30+i*5/2 }
 end
 @learnings = []
 @features.push(RPG::BaseItem::Feature.new(23, 0, 1))
 @features.push(RPG::BaseItem::Feature.new(22, 0, 0.95))
 @features.push(RPG::BaseItem::Feature.new(22, 1, 0.05))
 @features.push(RPG::BaseItem::Feature.new(22, 2, 0.04))
 @features.push(RPG::BaseItem::Feature.new(41, 1))
 @features.push(RPG::BaseItem::Feature.new(51, 1))
 @features.push(RPG::BaseItem::Feature.new(52, 1))
 end
 def exp_for_level(level)
 lv = level.to_f
 basis = @exp_params[0].to_f
 extra = @exp_params[1].to_f
 acc_a = @exp_params[2].to_f
 acc_b = @exp_params[3].to_f
 return (basis*((lv-1)**(0.9+acc_a/250))*lv*(lv+1)/
 (6+lv**2/50/acc_b)+(lv-1)*extra).round.to_i
 end
 attr_accessor :exp_params
 attr_accessor :params
 attr_accessor :learnings
end
```



######
