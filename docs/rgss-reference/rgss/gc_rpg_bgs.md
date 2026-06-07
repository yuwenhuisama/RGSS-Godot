# RPG::BGS


BGS のデータクラス。[Audio](gm_audio.md) モジュールを使って 自分自身を演奏する機能を持っています。

## スーパークラス


- [RPG::AudioFile](gc_rpg_audiofile.md)


## 参照元


- [RPG::Map](gc_rpg_map.md)
- [RPG::EventCommand](gc_rpg_eventcommand.md)


## クラスメソッド



### RPG::BGS.last



現在演奏中の BGS (RPG::BGS) を取得します。

同時に、取得したオブジェクトに現在の再生位置を保存します。

演奏中の BGM がない場合は、内容が空のオブジェクトを返します。

### RPG::BGS.stop



BGS を停止します。

### RPG::BGS.fade(*time*)



BGS のフェードアウトを開始します。*time* は、 フェードアウトにかける時間をミリ秒単位で指定します。

## メソッド



### play([*pos*])



この BGS の演奏を開始します。

ogg または wav の場合は、*pos* で演奏開始位置を指定できます。

### replay



RPG::BGS.last で取得した BGS の演奏を再開します。

## 定義


```

class RPG::BGS < RPG::AudioFile
 @@last = RPG::BGS.new
 def play(pos = 0)
 if @name.empty?
 Audio.bgs_stop
 @@last = RPG::BGS.new
 else
 Audio.bgs_play('Audio/BGS/' + @name, @volume, @pitch, pos)
 @@last = self.clone
 end
 end
 def replay
 play(@pos)
 end
 def self.stop
 Audio.bgs_stop
 @@last = RPG::BGS.new
 end
 def self.fade(time)
 Audio.bgs_fade(time)
 @@last = RPG::BGS.new
 end
 def self.last
 @@last.pos = Audio.bgs_pos
 @@last
 end
 attr_accessor :pos
end
```



######
