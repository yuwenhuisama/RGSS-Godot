# RPG::Animation


アニメーションのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 属性



### id


ID。

### name


名前。

### animation1_name


アニメーション グラフィック 1 のファイル名。

### animation1_hue


アニメーション グラフィック 1 の色相変化値 (0..360) 。

### animation2_name


アニメーション グラフィック 2 のファイル名。

### animation2_hue


アニメーション グラフィック 2 の色相変化値 (0..360) 。

### position


基準位置 (0:頭上、1:中心、2:足元、3:画面) 。

### frame_max


フレーム数。

### frames


フレームの内容。[RPG::Animation::Frame](gc_rpg_animation_frame.md) の配列です。

### timings


SE とフラッシュのタイミング。[RPG::Animation::Timing](gc_rpg_animation_timing.md) の配列です。

## メソッド



### to_screen?



画面全体に表示するアニメーションか否かを判定します。position の値が 3 のときに真を返します。

## 内部クラス


- [RPG::Animation::Frame](gc_rpg_animation_frame.md)
- [RPG::Animation::Timing](gc_rpg_animation_timing.md)


## 定義


```

class RPG::Animation
 def initialize
 @id = 0
 @name = ''
 @animation1_name = ''
 @animation1_hue = 0
 @animation2_name = ''
 @animation2_hue = 0
 @position = 1
 @frame_max = 1
 @frames = [RPG::Animation::Frame.new]
 @timings = []
 end
 def to_screen?
 @position == 3
 end
 attr_accessor :id
 attr_accessor :name
 attr_accessor :animation1_name
 attr_accessor :animation1_hue
 attr_accessor :animation2_name
 attr_accessor :animation2_hue
 attr_accessor :position
 attr_accessor :frame_max
 attr_accessor :frames
 attr_accessor :timings
end
```



######
