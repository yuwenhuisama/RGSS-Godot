# RPG::Event::Page::Graphic


イベントページの [グラフィック] のデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::Event::Page](gc_rpg_event_page.md)


## 属性



### tile_id


タイル ID。グラフィックの指定がタイルでない場合は 0 です。

### character_name


キャラクター グラフィックのファイル名。

### character_index


キャラクター グラフィックのインデックス (0..7)。

### direction


キャラクターの向き (2:下、4:左、6:右、8:上) 。

### pattern


キャラクターのパターン (0..2) 。

## 定義


```

class RPG::Event::Page::Graphic
 def initialize
 @tile_id = 0
 @character_name = ''
 @character_index = 0
 @direction = 2
 @pattern = 0
 end
 attr_accessor :tile_id
 attr_accessor :character_name
 attr_accessor :character_index
 attr_accessor :direction
 attr_accessor :pattern
end
```



######
