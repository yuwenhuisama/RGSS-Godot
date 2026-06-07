# RPG::MoveRoute


移動ルートのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::EventPage](gc_rpg_eventpage.md)


## 属性



### repeat


オプション [動作を繰り返す] の真偽値。

### skippable


オプション [移動できない場合は飛ばす] の真偽値。

### wait


オプション [移動が終わるまでウェイト] の真偽値。

### list


実行内容。[RPG::MoveCommand](gc_rpg_movecommand.md) の配列です。

## 定義


```

class RPG::MoveRoute
 def initialize
 @repeat = true
 @skippable = false
 @wait = false
 @list = [RPG::MoveCommand.new]
 end
 attr_accessor :repeat
 attr_accessor :skippable
 attr_accessor :wait
 attr_accessor :list
end
```



######
