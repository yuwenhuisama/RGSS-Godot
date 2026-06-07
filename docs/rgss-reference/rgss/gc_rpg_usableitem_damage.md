# RPG::UsableItem::Damage


ダメージのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::UsableItem](gc_rpg_usableitem.md)


## 属性



### type


ダメージタイプ。

- 0 : なし
- 1 : HP ダメージ
- 2 : MP ダメージ
- 3 : HP 回復
- 4 : MP 回復
- 5 : HP 吸収
- 6 : MP 吸収


### element_id


属性 ID。

### formula


計算式。

### variance


分散度。

### critical


会心 (true / false) 。

## メソッド



### none?



ダメージタイプが［なし］か否かを判定します。type の値が 0 のときに真を返します。

### to_hp?



HP に影響を与えるか否かを判定します。type の値が 1、3、5 のときに真を返します。

### to_mp?



MP に影響を与えるか否かを判定します。type の値が 2、4、6 のときに真を返します。

### recover?



回復か否かを判定します。type の値が 3、4 のときに真を返します。

### drain?



吸収か否かを判定します。type の値が 5、6 のときに真を返します。

### sign



ダメージの符号です。回復なら -1、それ以外なら 1 を返します。

### eval(*a*, *b*, *v*)



計算式の評価を行います。*a* に行動側バトラー、*b* に対象側バトラー、v にゲーム内変数の配列 ($game_variables) を指定します。

回復の場合は負の値を返します。

## 定義


```

class RPG::UsableItem::Damage
 def initialize
 @type = 0
 @element_id = 0
 @formula = '0'
 @variance = 20
 @critical = false
 end
 def none?
 @type == 0
 end
 def to_hp?
 [1,3,5].include?(@type)
 end
 def to_mp?
 [2,4,6].include?(@type)
 end
 def recover?
 [3,4].include?(@type)
 end
 def drain?
 [5,6].include?(@type)
 end
 def sign
 recover? ? -1 : 1
 end
 def eval(a, b, v)
 [Kernel.eval(@formula), 0].max * sign rescue 0
 end
 attr_accessor :type
 attr_accessor :element_id
 attr_accessor :formula
 attr_accessor :variance
 attr_accessor :critical
end
```



######
