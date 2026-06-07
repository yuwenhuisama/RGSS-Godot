# RPG::Troop::Page


バトルイベント (ページ) のデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::Troop](gc_rpg_troop.md)


## 属性



### condition


条件 ([RPG::Troop::Page::Condition](gc_rpg_troop_page_condition.md)) 。

### span


スパン (0:バトル、1:ターン、2:モーメント) 。

### list


実行内容。[RPG::EventCommand](gc_rpg_eventcommand.md) の配列です。

## 内部クラス


- [RPG::Troop::Page::Condition](gc_rpg_troop_page_condition.md)


## 定義


```

class RPG::Troop::Page
 def initialize
 @condition = RPG::Troop::Page::Condition.new
 @span = 0
 @list = [RPG::EventCommand.new]
 end
 attr_accessor :condition
 attr_accessor :span
 attr_accessor :list
end
```



######
