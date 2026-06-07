# RPG::Class::Learning


クラスの [習得するスキル] のデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::Class](gc_rpg_class.md)


## 属性



### level


レベル。

### skill_id


習得するスキルの ID。

### note


メモ。

## 定義


```

class RPG::Class::Learning
 def initialize
 @level = 1
 @skill_id = 1
 @note = ''
 end
 attr_accessor :level
 attr_accessor :skill_id
 attr_accessor :note
end
```



######
