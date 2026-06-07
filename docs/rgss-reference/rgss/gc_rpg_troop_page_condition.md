# RPG::Troop::Page::Condition


バトルイベントの [条件] のデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::Troop::Page](gc_rpg_troop_page.md)


## 属性



### turn_ending


条件 [ターン終了時] が有効かどうかを示す真偽値。

### turn_valid


条件 [ターン数] が有効かどうかを示す真偽値。

### enemy_valid


条件 [敵キャラ] が有効かどうかを示す真偽値。

### actor_valid


条件 [アクター] が有効かどうかを示す真偽値。

### switch_valid


条件 [スイッチ] が有効かどうかを示す真偽値。

### turn_a


### turn_b


条件 [ターン数] に指定された A、B の値。A + B * X の形で入力されます。

### enemy_index


条件 [敵キャラ] に指定された、敵グループメンバーのインデックス (0..7)。

### enemy_hp


条件 [敵キャラ] に指定された HP の割合 (%) 。

### actor_id


条件 [アクター] に指定されたアクターの ID。

### actor_hp


条件 [アクター] に指定された HP の割合 (%) 。

### switch_id


条件 [スイッチ] に指定されたスイッチの ID。

## 定義


```

class RPG::Troop::Page::Condition
 def initialize
 @turn_ending = false
 @turn_valid = false
 @enemy_valid = false
 @actor_valid = false
 @switch_valid = false
 @turn_a = 0
 @turn_b = 0
 @enemy_index = 0
 @enemy_hp = 50
 @actor_id = 1
 @actor_hp = 50
 @switch_id = 1
 end
 attr_accessor :turn_ending
 attr_accessor :turn_valid
 attr_accessor :enemy_valid
 attr_accessor :actor_valid
 attr_accessor :switch_valid
 attr_accessor :turn_a
 attr_accessor :turn_b
 attr_accessor :enemy_index
 attr_accessor :enemy_hp
 attr_accessor :actor_id
 attr_accessor :actor_hp
 attr_accessor :switch_id
end
```



######
