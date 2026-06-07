# RPG::SE


SE のデータクラス。[Audio](gm_audio.md) モジュールを使って 自分自身を演奏する機能を持っています。

## スーパークラス


- [RPG::AudioFile](gc_rpg_audiofile.md)


## 参照元


- [RPG::Animation::Timing](gc_rpg_animation_timing.md)
- [RPG::System](gc_rpg_system.md)
- [RPG::EventCommand](gc_rpg_eventcommand.md)
- [RPG::MoveCommand](gc_rpg_movecommand.md)


## クラスメソッド



### RPG::SE.stop



SE を停止します。

## メソッド



### play



この SE の演奏を開始します。

## 定義


```

class RPG::SE < RPG::AudioFile
 def play
 unless @name.empty?
 Audio.se_play('Audio/SE/' + @name, @volume, @pitch)
 end
 end
 def self.stop
 Audio.se_stop
 end
end
```



######
