# RPG::UsableItem


スキルとアイテムのスーパークラス。

## スーパークラス


- [RPG::BaseItem](gc_rpg_baseitem.md)


## 属性



### scope


効果範囲。

- 0 : なし
- 1 : 敵単体
- 2 : 敵全体
- 3 : 敵 1 体 ランダム
- 4 : 敵 2 体 ランダム
- 5 : 敵 3 体 ランダム
- 6 : 敵 4 体 ランダム
- 7 : 味方単体
- 8 : 味方全体
- 9 : 味方単体 (戦闘不能)
- 10 : 味方全体 (戦闘不能)
- 11 : 使用者


### occasion


使用可能時。

- 0 : 常時
- 1 : バトルのみ
- 2 : メニューのみ
- 3 : 使用不可


### speed


速度補正。

### success_rate


成功率。

### repeats


連続回数。

### tp_gain


得 TP。

### hit_type


命中タイプ。

- 0 : 必中
- 1 : 物理攻撃
- 2 : 魔法攻撃


### animation_id


アニメーション ID。

### damage


ダメージ ([RPG::UsableItem::Damage](gc_rpg_usableitem_damage.md)) 。

### effects


使用効果リスト。[RPG::UsableItem::Effect](gc_rpg_usableitem_effect.md) の配列です。

## メソッド



### for_opponent?



効果範囲が敵か否かを判定します。scope の値が 1、2、3、4、5、6 のときに真を返します。

### for_friend?



効果範囲が味方か否かを判定します。scope の値が 7、8、9、10、11 のときに真を返します。

### for_dead_friend?



効果範囲が戦闘不能の味方か否かを判定します。scope の値が 9、10 のときに真を返します。

### for_user?



効果範囲が使用者か否かを判定します。scope の値が 11 のときに真を返します。

### for_one?



効果範囲が単体か否かを判定します。scope の値が 1、3、7、9、11 のときに真を返します。

### for_random?



効果範囲がランダムかを判定します。scope の値が 3、4、5、6 のときに真を返します。

### number_of_targets



効果範囲がランダムの場合の対象数です。

### for_all?



効果範囲が全体か否かを判定します。scope の値が 2、9、10 のときに真を返します。

### need_selection?



対象の選択操作が必要か否かを判定します。scope の値が 1、7、9 のときに真を返します。

### battle_ok?



バトル画面で使用可能か否かを判定します。occasion の値が 0、1 のときに真を返します。

### menu_ok?



メニュー画面で使用可能か否かを判定します。occasion の値が 0、2 のときに真を返します。

### certain?



命中タイプが必中か否かを判定します。hit_type の値が 0 のときに真を返します。

### physical?



命中タイプが物理攻撃か否かを判定します。hit_type の値が 1 のときに真を返します。

### magical?



命中タイプが魔法攻撃か否かを判定します。hit_type の値が 2 のときに真を返します。

## 内部クラス


- [RPG::UsableItem::Damage](gc_rpg_usableitem_damage.md)
- [RPG::UsableItem::Effect](gc_rpg_usableitem_effect.md)


## 定義


```

class RPG::UsableItem < RPG::BaseItem
 def initialize
 super
 @scope = 0
 @occasion = 0
 @speed = 0
 @success_rate = 100
 @repeats = 1
 @tp_gain = 0
 @hit_type = 0
 @animation_id = 0
 @damage = RPG::UsableItem::Damage.new
 @effects = []
 end
 def for_opponent?
 [1, 2, 3, 4, 5, 6].include?(@scope)
 end
 def for_friend?
 [7, 8, 9, 10, 11].include?(@scope)
 end
 def for_dead_friend?
 [9, 10].include?(@scope)
 end
 def for_user?
 @scope == 11
 end
 def for_one?
 [1, 3, 7, 9, 11].include?(@scope)
 end
 def for_random?
 [3, 4, 5, 6].include?(@scope)
 end
 def number_of_targets
 for_random? ? @scope - 2 : 0
 end
 def for_all?
 [2, 8, 10].include?(@scope)
 end
 def need_selection?
 [1, 7, 9].include?(@scope)
 end
 def battle_ok?
 [0, 1].include?(@occasion)
 end
 def menu_ok?
 [0, 2].include?(@occasion)
 end
 def certain?
 @hit_type == 0
 end
 def physical?
 @hit_type == 1
 end
 def magical?
 @hit_type == 2
 end
 attr_accessor :scope
 attr_accessor :occasion
 attr_accessor :speed
 attr_accessor :animation_id
 attr_accessor :success_rate
 attr_accessor :repeats
 attr_accessor :tp_gain
 attr_accessor :hit_type
 attr_accessor :damage
 attr_accessor :effects
end
```



######
