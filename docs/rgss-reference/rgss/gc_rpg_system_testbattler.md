# RPG::System::TestBattler


戦闘テストで使用するアクターのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::System](gc_rpg_system.md)


## 属性



### actor_id


アクター ID。

### level


レベル。

### equips


装備。以下を添字とする、武器 ID または防具 ID の配列です。

- 0 : 武器
- 1 : 盾
- 2 : 頭
- 3 : 身体
- 4 : 装飾品


## 定義


```

class RPG::System::TestBattler
 def initialize
 @actor_id = 1
 @level = 1
 @equips = [0,0,0,0,0]
 end
 attr_accessor :actor_id
 attr_accessor :level
 attr_accessor :equips
end
```



######
