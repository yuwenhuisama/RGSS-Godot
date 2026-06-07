# RPG::EventCommand


イベントコマンドのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::Event::Page](gc_rpg_event_page.md)
- [RPG::Troop::Page](gc_rpg_troop_page.md)
- [RPG::CommonEvent](gc_rpg_commonevent.md)


## 属性



### code


イベントコード。

### indent


インデントの深さ。通常 0 で、[条件分岐] コマンドなどで 一段深くなるごとに +1 されます。

### parameters


イベントコマンドの引数を格納した配列。 内容はコマンドごとに異なります。

## 定義


```

class RPG::EventCommand
 def initialize(code = 0, indent = 0, parameters = [])
 @code = code
 @indent = indent
 @parameters = parameters
 end
 attr_accessor :code
 attr_accessor :indent
 attr_accessor :parameters
end
```



######
