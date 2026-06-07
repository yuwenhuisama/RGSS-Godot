# RPG::Event::Page


イベントページのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::Event](gc_rpg_event.md)


## 属性



### condition


条件 ([RPG::Event::Page::Condition](gc_rpg_event_page_condition.md)) 。

### graphic


グラフィック ([RPG::Event::Page::Graphic](gc_rpg_event_page_graphic.md)) 。

### move_type


移動タイプ (0:固定、1:ランダム、2:近づく、3:カスタム) 。

### move_speed


移動速度 (1:1/8倍速、2:1/4倍速、3:1/2倍速、4:標準速、5:2倍速、6:4倍速) 。

### move_frequency


移動頻度 (1:最低、2:低、3:通常、4:高、5:最高) 。

### move_route


移動ルート ([RPG::MoveRoute](gc_rpg_moveroute.md)) 。 移動タイプがカスタムの場合のみ参照されます。

### walk_anime


オプション [歩行アニメ] の真偽値。

### step_anime


オプション [足踏みアニメ] の真偽値。

### direction_fix


オプション [向き固定] の真偽値。

### through


オプション [すり抜け] の真偽値。

### priority_type


プライオリティタイプ (0:通常キャラの下、1:通常キャラと 同じ、2:通常キャラの上) 。

### trigger


トリガー (0:決定ボタン、1:プレイヤーから接触、2:イベント から接触、3:自動実行、4:並列処理) 。

### list


実行内容。[RPG::EventCommand](gc_rpg_eventcommand.md) の配列です。

## 内部クラス


- [RPG::Event::Page::Condition](gc_rpg_event_page_condition.md)
- [RPG::Event::Page::Graphic](gc_rpg_event_page_graphic.md)


## 定義


```

class RPG::Event::Page
 def initialize
 @condition = RPG::Event::Page::Condition.new
 @graphic = RPG::Event::Page::Graphic.new
 @move_type = 0
 @move_speed = 3
 @move_frequency = 3
 @move_route = RPG::MoveRoute.new
 @walk_anime = true
 @step_anime = false
 @direction_fix = false
 @through = false
 @priority_type = 0
 @trigger = 0
 @list = [RPG::EventCommand.new]
 end
 attr_accessor :condition
 attr_accessor :graphic
 attr_accessor :move_type
 attr_accessor :move_speed
 attr_accessor :move_frequency
 attr_accessor :move_route
 attr_accessor :walk_anime
 attr_accessor :step_anime
 attr_accessor :direction_fix
 attr_accessor :through
 attr_accessor :priority_type
 attr_accessor :trigger
 attr_accessor :list
end
```



######
