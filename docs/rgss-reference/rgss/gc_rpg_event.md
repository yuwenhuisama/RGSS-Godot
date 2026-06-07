# RPG::Event


マップイベントのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::Map](gc_rpg_map.md)


## 属性



### id


ID。

### name


名前。

### x


マップ X 座標。

### y


マップ Y 座標。

### pages


イベントページ。[RPG::Event::Page](gc_rpg_event_page.md) の配列です。

## 内部クラス


- [RPG::Event::Page](gc_rpg_event_page.md)


## 定義


```

class RPG::Event
 def initialize(x, y)
 @id = 0
 @name = ''
 @x = x
 @y = y
 @pages = [RPG::Event::Page.new]
 end
 attr_accessor :id
 attr_accessor :name
 attr_accessor :x
 attr_accessor :y
 attr_accessor :pages
end
```



######
