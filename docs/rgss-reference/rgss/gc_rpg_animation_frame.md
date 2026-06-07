# RPG::Animation::Frame


アニメーションフレームのデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::Animation](gc_rpg_animation.md)


## 属性



### cell_max


セルの数。フレームに存在する最大のセル番号と同じです。

### cell_data


セルの内容を格納した二次元配列 ([Table](gc_table.md)) 。

具体的には、cell_data[*cell_index*, *data_index*] という 形式になっています。

*data_index* の範囲は 0..7 で、セルの各情報を表します (0:パターン、1:X 座標、2:Y 座標、3:拡大率、4:回転角度、5:左右 反転、6:不透明度、7:合成方法) 。パターンはツクールで表示される番号から 1 を引いた数字です。-1 はそのセルが欠番であることを意味します。

## 定義


```

class RPG::Animation::Frame
 def initialize
 @cell_max = 0
 @cell_data = Table.new(0, 0)
 end
 attr_accessor :cell_max
 attr_accessor :cell_data
end
```



######
