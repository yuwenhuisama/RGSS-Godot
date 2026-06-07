# RPG::CommonEvent


コモンイベントのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 属性



### id


ID。

### name


名前。

### trigger


トリガー (0:なし、1:自動実行、2:並列処理) 。

### switch_id


条件スイッチの ID。

### list


実行内容。[RPG::EventCommand](gc_rpg_eventcommand.md) の配列です。

## メソッド



### autorun?


自動実行のイベントか否かを判定します。trigger の値が 1 のときに真を返します。

### parallel?


並列処理のイベントか否かを判定します。trigger の値が 2 のときに真を返します。

## 定義


```

class RPG::CommonEvent
 def initialize
 @id = 0
 @name = ''
 @trigger = 0
 @switch_id = 1
 @list = [RPG::EventCommand.new]
 end
 def autorun?
 @trigger == 1
 end
 def parallel?
 @trigger == 2
 end
 attr_accessor :id
 attr_accessor :name
 attr_accessor :trigger
 attr_accessor :switch_id
 attr_accessor :list
end
```



######
