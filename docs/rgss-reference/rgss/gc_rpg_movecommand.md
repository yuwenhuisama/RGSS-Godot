# RPG::MoveCommand


移動コマンドのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::MoveRoute](gc_rpg_moveroute.md)


## 属性



### code


移動コマンドコード。

### parameters


移動コマンドの引数を格納した配列。内容はコマンドごとに異なります。

## 定義


```

class RPG::MoveCommand
 def initialize(code = 0, parameters = [])
 @code = code
 @parameters = parameters
 end
 attr_accessor :code
 attr_accessor :parameters
end
```



######
