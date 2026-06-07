# RPG::MapInfo


マップ情報のデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 属性



### name


名前。

### parent_id


親マップの ID。

### order


ツクール内部で使用するマップツリー表示順序。

### expanded


ツクール内部で使用するマップツリー展開フラグ。

### scroll_x


ツクール内部で使用する X 方向のスクロール位置。

### scroll_y


ツクール内部で使用する Y 方向のスクロール位置。

## 定義


```

class RPG::MapInfo
 def initialize
 @name = ''
 @parent_id = 0
 @order = 0
 @expanded = false
 @scroll_x = 0
 @scroll_y = 0
 end
 attr_accessor :name
 attr_accessor :parent_id
 attr_accessor :order
 attr_accessor :expanded
 attr_accessor :scroll_x
 attr_accessor :scroll_y
end
```



######
