# Bitmap


ビットマップのクラス。ビットマップは、いわゆる画像そのものを表し ます。

画面にビットマップを表示するためにはスプライト ([Sprite](gc_sprite.md)) などを使う必要があります。

## スーパークラス


- [Object](sc_object.md)


## クラスメソッド



### Bitmap.new(*filename*)



*filename* で指定した画像ファイルを読み込み、Bitmap オブジェクトを 生成します。

[RGSS-RTP](rgss.md#rgss_rtp)、[暗号化アーカイブ](rgss.md#encryption_archive)に含まれるファイルも自動的に 探します。拡張子は省略可能です。

### Bitmap.new(*width*, *height*)



指定したサイズの Bitmap オブジェクトを生成します。

## メソッド



### dispose



ビットマップを解放します。すでに解放されている場合は何も行いません。

### disposed?



ビットマップがすでに解放されている場合に真を返します。

### width



ビットマップの幅を取得します。

### height



ビットマップの高さを取得します。

### rect



ビットマップの矩形 ([Rect](gc_rect.md)) を取得します。

### blt(*x*, *y*, *src_bitmap*, *src_rect*[, *opacity*])



*src_bitmap* の矩形 *src_rect* ([Rect](gc_rect.md)) から、このビットマップの座標 (*x*, *y*) にブロック転送を行います。

*opacity* には不透明度を 0 ～ 255 の範囲で指定できます。

### stretch_blt(*dest_rect*, *src_bitmap*, *src_rect*[, *opacity*])



*src_bitmap* の矩形 *src_rect* ([Rect](gc_rect.md)) から、このビットマップの矩形 *dest_rect* ([Rect](gc_rect.md)) にブロック転送を行います。

*opacity* には不透明度を 0 ～ 255 の範囲で指定できます。

### fill_rect(*x*, *y*, *width*, *height*, *color*)


### fill_rect(*rect*, *color*)



このビットマップの矩形 (*x*, *y*, *width*, *height*) または *rect* ([Rect](gc_rect.md)) を *color* ([Color](gc_color.md)) で塗り潰します。

### gradient_fill_rect(*x*, *y*, *width*, *height*, *color1*, *color2*[, *vertical*])


### gradient_fill_rect(*rect*, *color1*, *color2*[, *vertical*])



このビットマップの矩形 (*x*, *y*, *width*, *height*) または *rect* ([Rect](gc_rect.md)) を、*color1* ([Color](gc_color.md)) から *color2* ([Color](gc_color.md)) のグラデーションで 塗り潰します。

*vertical* に true を指定すると縦方向のグラデーションに なります。デフォルトは横方向です。

### clear



ビットマップ全体をクリアします。

### clear_rect(*x*, *y*, *width*, *height*)


### clear_rect(*rect*)



このビットマップの矩形 (*x*, *y*, *width*, *height*) または *rect* ([Rect](gc_rect.md)) をクリアします。

### get_pixel(*x*, *y*)



点 (*x*, *y*) の色 ([Color](gc_color.md)) を取得します。

### set_pixel(*x*, *y*, *color*)



点 (*x*, *y*) の色を *color* ([Color](gc_color.md)) に設定します。

### hue_change(*hue*)



色相を変換します。*hue* は色相 (360 度系) の変位を指定します。

この処理には時間がかかります。また、変換誤差のため、何度も変換を繰り返すと 色が失われます。

### blur



ビットマップにぼかし効果を適用します。この処理には時間がかかります。

### radial_blur(*angle*, *division*)



ビットマップに放射状のぼかし効果を適用します。 *angle* は角度 (0 ～ 360) で、大きいほど丸くなります。

*division* は分割数 (2 ～ 100) で、大きいほど滑らかになります。 この処理には非常に時間がかかります。

### draw_text(*x*, *y*, *width*, *height*, *str*[, *align*])


### draw_text(*rect*, *str*[, *align*])



このビットマップの矩形 (*x*, *y*, *width*, *height*) または *rect* ([Rect](gc_rect.md)) に 文字列 *str* を描画します。

*str* が文字列のオブジェクトでない場合には、to_s メソッドにより 文字列に変換してから処理を行います。

テキストの長さが矩形の幅を超える場合は、幅を 60% まで自動的に縮小して 描画します。

水平方向はデフォルトで左揃えですが、*align* に 1 を指定すると 中央揃え、2 を指定すると右揃えになります。垂直方向は常に中央揃えです。

この処理には時間がかかるため、1 フレームごとに文字列を再描画するような 使い方は推奨されません。

### text_size(*str*)



draw_text メソッドで文字列 *str* を描画したときの矩形 ([Rect](gc_rect.md)) を取得します。ただし、縁取りの分 (RGSS3) およびイタリックの傾き分は含みません。

*str* が文字列のオブジェクトでない場合には、to_s メソッドにより 文字列に変換してから処理を行います。

## プロパティ



### font



draw_text メソッドで文字列の描画に使用するフォント ([Font](gc_font.md)) です。

######
