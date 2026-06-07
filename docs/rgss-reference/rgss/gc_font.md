# Font


フォントのクラス。フォントは [Bitmap](gc_bitmap.md) クラスの プロパティです。

ゲームフォルダ直下に "Fonts" フォルダがある場合、その中のフォントファイルは システムにインストールされていなくても使用することができます。

## スーパークラス


- [Object](sc_object.md)


## クラスメソッド



### Font.new([*name*[, *size*]])



Font オブジェクトを生成します。

### Font.exist?(*name*)



指定された名前のフォントがシステムに存在するとき真を返します。

## プロパティ



### name



フォント名です。初期値は "VL Gothic" (RGSS3) です。

文字列の配列を設定すると、希望順に複数指定することができます。

```

font.name = ["HGP行書体", "ＭＳ ゴシック"]
```



上の例の場合、第一希望の "HGP行書体" がシステムに存在 しなければ、第二希望の "ＭＳ ゴシック" が使用されること になります。

### size



フォントのサイズです。初期値は 24 (RGSS3) です。

### bold



ボールドフラグです。初期値は false です。

### italic



イタリックフラグです。初期値は false です。

### outline (RGSS3)



縁取り文字のフラグです。初期値は true です。

### shadow



影付き文字のフラグです。初期値は false (RGSS3) です。 有効な場合、文字の右下に黒色で影を描画します。

### color



フォントの色 ([Color](gc_color.md)) です。 アルファ値も有効です。初期値は (255,255,255,255) です。

アルファ値は、縁取り (RGSS3) や影の描画にも反映されます。

### out_color (RGSS3)



縁取りの色 ([Color](gc_color.md)) です。 初期値は (0,0,0,128) です。

## クラスプロパティ



### default_name


### default_size


### default_bold


### default_italic


### default_shadow


### default_outline (RGSS3)


### default_color


### default_out_color (RGSS3)



Font オブジェクトが新しく作成されたときに各要素に設定される デフォルト値を変更できます。

```

Font.default_name = "ＭＳ 明朝"
Font.default_size = 22
Font.default_bold = true
```



######
