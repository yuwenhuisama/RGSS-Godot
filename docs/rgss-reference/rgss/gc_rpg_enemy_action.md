# RPG::Enemy::Action


敵キャラの [戦闘行動] のデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::Enemy](gc_rpg_enemy.md)


## 属性



### skill_id


戦闘行動として採用するスキルの ID。

### condition_type


行動条件のタイプ。

- 0 : 常時
- 1 : ターン数
- 2 : HP
- 3 : MP
- 4 : ステート
- 5 : パーティレベル
- 6 : スイッチ


### condition_param1


### condition_param2


行動条件のパラメータ。全タイプで共用となります。

たとえば条件が [HP] の場合は、condition_param1 に下限、 condition_param2 に上限の値が入ります。

### rating


優先度 (1..10) 。

## 定義


```

class RPG::Enemy::Action
 def initialize
 @skill_id = 1
 @condition_type = 0
 @condition_param1 = 0
 @condition_param2 = 0
 @rating = 5
 end
 attr_accessor :skill_id
 attr_accessor :condition_type
 attr_accessor :condition_param1
 attr_accessor :condition_param2
 attr_accessor :rating
end
```



######
