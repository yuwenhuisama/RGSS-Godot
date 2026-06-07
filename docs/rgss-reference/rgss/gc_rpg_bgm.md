# RPG::BGM


BGM のデータクラス。[Audio](gm_audio.md) モジュールを使って 自分自身を演奏する機能を持っています。

## スーパークラス


- [RPG::AudioFile](gc_rpg_audiofile.md)


## 参照元


- [RPG::Map](gc_rpg_map.md)
- [RPG::System](gc_rpg_system.md)
- [RPG::System::Vehicle](gc_rpg_system_vehicle.md)
- [RPG::EventCommand](gc_rpg_eventcommand.md)


## クラスメソッド



### RPG::BGM.last



現在演奏中の BGM (RPG::BGM) を取得します。

同時に、取得したオブジェクトに現在の再生位置を保存します。

演奏中の BGM がない場合は、内容が空のオブジェクトを返します。

### RPG::BGM.stop



BGM を停止します。

### RPG::BGM.fade(*time*)



BGM のフェードアウトを開始します。*time* は、 フェードアウトにかける時間をミリ秒単位で指定します。

## メソッド



### play([*pos*])



この BGM の演奏を開始します。

ogg または wav の場合は、*pos* で演奏開始位置を指定できます。

### replay



RPG::BGM.last で取得した BGM の演奏を再開します。

## 定義


```

class RPG::BGM < RPG::AudioFile
 @@last = RPG::BGM.new
 def play(pos = 0)
 if @name.empty?
 Audio.bgm_stop
 @@last = RPG::BGM.new
 else
 Audio.bgm_play('Audio/BGM/' + @name, @volume, @pitch, pos)
 @@last = self.clone
 end
 end
 def replay
 play(@pos)
 end
 def self.stop
 Audio.bgm_stop
 @@last = RPG::BGM.new
 end
 def self.fade(time)
 Audio.bgm_fade(time)
 @@last = RPG::BGM.new
 end
 def self.last
 @@last.pos = Audio.bgm_pos
 @@last
 end
 attr_accessor :pos
end
```



######
