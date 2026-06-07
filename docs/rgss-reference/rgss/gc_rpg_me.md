# RPG::ME


ME のデータクラス。[Audio](gm_audio.md) モジュールを使って 自分自身を演奏する機能を持っています。

## スーパークラス


- [RPG::AudioFile](gc_rpg_audiofile.md)


## 参照元


- [RPG::System](gc_rpg_system.md)
- [RPG::EventCommand](gc_rpg_eventcommand.md)


## クラスメソッド



### RPG::ME.stop



ME を停止します。

### RPG::ME.fade(*time*)



ME のフェードアウトを開始します。*time* は、 フェードアウトにかける時間をミリ秒単位で指定します。

## メソッド



### play



この ME の演奏を開始します。

## 定義


```

class RPG::ME < RPG::AudioFile
 def play
 if @name.empty?
 Audio.me_stop
 else
 Audio.me_play('Audio/ME/' + @name, @volume, @pitch)
 end
 end
 def self.stop
 Audio.me_stop
 end
 def self.fade(time)
 Audio.me_fade(time)
 end
end
```



######
