# RPG::Event::Page::Condition


イベントページの [条件] のデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::Event::Page](gc_rpg_event_page.md)


## 属性



### switch1_valid


条件 [スイッチ] (一番目) が有効かどうかを示す真偽値。

### switch2_valid


条件 [スイッチ] (二番目) が有効かどうかを示す真偽値。

### variable_valid


条件 [変数] が有効かどうかを示す真偽値。

### self_switch_valid


条件 [セルフスイッチ] が有効かどうかを示す真偽値。

### item_valid


条件 [アイテム] が有効かどうかを示す真偽値。

### actor_valid


条件 [アクター] が有効かどうかを示す真偽値。

### switch1_id


条件 [スイッチ] (一番目) が有効なとき、そのスイッチ ID。

### switch2_id


条件 [スイッチ] (二番目) が有効なとき、そのスイッチ ID。

### variable_id


条件 [変数] が有効なとき、その変数 ID。

### variable_value


条件 [変数] が有効なとき、その変数の基準値 (x 以上) 。

### self_switch_ch


条件 [セルフスイッチ] が有効なとき、 その文字 ("A".."D") 。

### item_id


条件 [アイテム] が有効なとき、そのアイテム ID。

### actor_id


条件 [アクター] が有効なとき、そのアクター ID。

## 定義


```

class RPG::Event::Page::Condition
 def initialize
 @switch1_valid = false
 @switch2_valid = false
 @variable_valid = false
 @self_switch_valid = false
 @item_valid = false
 @actor_valid = false
 @switch1_id = 1
 @switch2_id = 1
 @variable_id = 1
 @variable_value = 0
 @self_switch_ch = 'A'
 @item_id = 1
 @actor_id = 1
 end
 attr_accessor :switch1_valid
 attr_accessor :switch2_valid
 attr_accessor :variable_valid
 attr_accessor :self_switch_valid
 attr_accessor :item_valid
 attr_accessor :actor_valid
 attr_accessor :switch1_id
 attr_accessor :switch2_id
 attr_accessor :variable_id
 attr_accessor :variable_value
 attr_accessor :self_switch_ch
 attr_accessor :item_id
 attr_accessor :actor_id
end
```



######
