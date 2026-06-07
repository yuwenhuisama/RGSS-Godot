# RPG::Animation::Timing


アニメーションの [SE とフラッシュのタイミング] のデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::Animation](gc_rpg_animation.md)


## 属性



### frame


フレーム番号。ツクールで表示される番号から 1 を引いた数字です。

### se


SE ([RPG::SE](gc_rpg_se.md)) 。

### flash_scope


フラッシュの範囲 (0:なし、1:対象、2:画面、3:対象消去) 。

### flash_color


フラッシュの色 ([Color](gc_color.md)) 。

### flash_duration


フラッシュの持続時間。

## 定義


```

class RPG::Animation::Timing
 def initialize
 @frame = 0
 @se = RPG::SE.new('', 80)
 @flash_scope = 0
 @flash_color = Color.new(255,255,255,255)
 @flash_duration = 5
 end
 attr_accessor :frame
 attr_accessor :se
 attr_accessor :flash_scope
 attr_accessor :flash_color
 attr_accessor :flash_duration
end
```



######
