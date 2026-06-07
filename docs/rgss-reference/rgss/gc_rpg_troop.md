# RPG::Troop


敵グループのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 属性



### id


ID。

### name


名前。

### members


敵グループのメンバー。[RPG::Troop::Member](gc_rpg_troop_member.md) の配列です。

### pages


バトルイベント。[RPG::Troop::Page](gc_rpg_troop_page.md) の配列です。

## 内部クラス


- [RPG::Troop::Member](gc_rpg_troop_member.md)
- [RPG::Troop::Page](gc_rpg_troop_page.md)


## 定義


```

class RPG::Troop
 def initialize
 @id = 0
 @name = ''
 @members = []
 @pages = [RPG::Troop::Page.new]
 end
 attr_accessor :id
 attr_accessor :name
 attr_accessor :members
 attr_accessor :pages
end
```



######
