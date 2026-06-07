# RPG::Tileset


タイルセットのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 属性



### id


ID。

### name


名前。

### mode


モード (0:フィールドタイプ、1:エリアタイプ、2:VX 互換タイプ) 。

### tileset_names[*index*]



番号 *index* (0 ～ 8) のタイルセットとして使用する グラフィックのファイル名。

番号とセットの対応は以下のようになります。

| 0 | TileA1 | 1 | TileA2 | 2 | TileA3 |
| --- | --- | --- | --- | --- | --- |
| 3 | TileA4 | 4 | TileA5 | 5 | TileB |
| 6 | TileC | 7 | TileD | 8 | TileE |



### flags


フラグテーブル。各種フラグを格納した 一次元配列 ([Table](gc_table.md)) です。

タイル ID を添字として取ります。各ビットの対応は以下の通りです。

- 0x0001 : 下方向通行不可。
- 0x0002 : 左方向通行不可。
- 0x0004 : 右方向通行不可。
- 0x0008 : 上方向通行不可。
- 0x0010 : 通常キャラの上に表示。
- 0x0020 : 梯子。
- 0x0040 : 茂み。
- 0x0080 : カウンター。
- 0x0100 : ダメージ床。
- 0x0200 : 小型船通行禁止。
- 0x0400 : 大型船通行禁止。
- 0x0800 : 飛行船着陸禁止。
- 0xF000 : 地形タグ。


ビット演算に関してはこのマニュアルでは解説して いませんが、C 言語などと共通です。必要な場合は、インターネット にて「16 進数 ビット演算」等のキーワードで検索することを お勧めします。

### note


メモ。

## 定義


```

class RPG::Tileset
 def initialize
 @id = 0
 @mode = 1
 @name = ''
 @tileset_names = Array.new(9).collect{''}
 @flags = Table.new(8192)
 @flags[0] = 0x0010
 (2048..2815).each {|i| @flags[i] = 0x000F}
 (4352..8191).each {|i| @flags[i] = 0x000F}
 @note = ''
 end
 attr_accessor :id
 attr_accessor :mode
 attr_accessor :name
 attr_accessor :tileset_names
 attr_accessor :flags
 attr_accessor :note
end
```



######
