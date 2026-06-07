# RPG::AudioFile


BGM、BGS、ME、SE のスーパークラス。

## スーパークラス


- [Object](sc_object.md)


## 属性



### name


ファイル名。

### volume


ボリューム (0..100) 。BGM、ME では 100 が、BGS、SE では 80 が標準値です。

### pitch


ピッチ (50..150) 。100 が標準値です。

## 定義


```

class RPG::AudioFile
 def initialize(name = '', volume = 100, pitch = 100)
 @name = name
 @volume = volume
 @pitch = pitch
 end
 attr_accessor :name
 attr_accessor :volume
 attr_accessor :pitch
end
```



######
