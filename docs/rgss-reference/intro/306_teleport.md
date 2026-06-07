# テレポートアイテムの作成


- [アイテムデータの作成](#data)
- [ウィンドウの作成](#window)
- [ウィンドウの表示](#show)
- [場所テーブルの作成](#places)
- [テレポート位置の選択](#select)
- [ハンドラの設定](#handler)


メニュー画面でアイテムやスキルを選択したときに、さらに別の ウィンドウで選択処理を行う方法を解説します。

例として、町などのリストから任意の場所を選択して瞬間移動する アイテムを作成します。

## アイテムデータの作成


[脱出アイテムの作成](303_escape.md)のときと 同じように、テレポート用アイテムのデータを設定します。

効果範囲は［なし］、使用可能時は［メニューのみ］とし、メモには <TELEPORT> と入力しましょう (<>を含む) 。 設定が終わったら、イベントコマンド［アイテムの増減］を含んだ イベントを作成し、効果をテストできるようにしてください。

なお、便宜上［アイテム］を使用して説明していますが、ここで 作成するスクリプトはそのままで［スキル］にも対応しています。 つまり、スキルのメモに <TELEPORT> と書き、効果範囲と使用可能時を 同様に設定すれば、それだけでスキルも作成することが可能です。

## ウィンドウの作成


テレポート位置を選択させるためのウィンドウクラスを作成します。

今回は Window_Selectable クラスではなく、Window_Command クラスを継承してみましょう。使い分けはケースバイ ケースですが、Window_Command クラスを使えば選択肢を描画するコードを 自分で書く必要がないため、比較的扱いが簡単です。

```

class Window_Teleport < Window_Command
 def initialize
 super(0, 0)
 hide
 deactivate
 end
end
```



Window_Command クラスの initialize メソッドは、X 座標および Y 座標の二つの引数を取ります。座標の指定は今回 不要なので、Window_Teleport クラスの initialize メソッドは 引数なしとし、super(0, 0) という形でスーパークラスのメソッドを 呼び出すことで X 座標、Y 座標とも 0 に設定しています。

続いて hide メソッドを呼び出して非表示状態に、deactivate メソッドを呼び出して非アクティブ状態にしています。このウィンドウが 実際に作成されるのはアイテム画面に移った時点なので、アイテムを 選択してもいないのに表示されてしまっては都合が悪いからです。

次にサイズの指定が必要です。次のコードを Window_Teleport クラスの中に記述してください。

```

 def window_width
 return 240
 end
 def window_height
 Graphics.height
 end
```



Window_Command クラスでは、ウィンドウの幅と高さを自分自身の window_width、window_height メソッドを呼ぶことで取得するように なっています。これは、たとえばコマンドの数によってウィンドウの 高さを調整するなどの処理を柔軟に行えるようにするための設計です。

今回は、幅として 240、高さとして Graphics.height を返しています。なお、[Graphics.height](../rgss/gm_graphics.md#height) というのは画面全体の高さを返すメソッドです。

## ウィンドウの表示


前項で作成したウィンドウを、Scene_ItemBase クラスのインスタンス変数として持たせます。次のように start メソッドを再定義し、Window_Teleport クラスのインスタンスを生成 する処理を加えます。なお、[あらすじ画面の作成](302_story.md)の際にも触れましたが、Window_Base クラスに全ウィンドウの解放処理が含まれているため、dispose を記述する必要はありません。

```

class Scene_ItemBase
 alias xxx001_start start
 def start
 xxx001_start
 @teleport_window = Window_Teleport.new
 end
end
```



続いて determine_item メソッドを再定義します。

```

 alias xxx001_determine_item determine_item
 def determine_item
 if item.note.include?("<TELEPORT>")
 show_sub_window(@teleport_window)
 else
 xxx001_determine_item
 end
 end
```



determine_item は、アイテムにカーソルを合わせて決定ボタンを 押した瞬間に呼び出されるメソッドです。ここでは、メモに <TELEPORT> という文字列が含まれていれば show_sub_window メソッドを呼び出し、そうでなければ通常の処理を行うように 指定しています。

show_sub_window は、アイテム画面やスキル画面の上に別の ウィンドウを表示するためのメソッドです。デフォルトではアクターの 選択のみに使用しています。このメソッドはビューポートの位置などを 操作することで、ウィンドウ同士が重なって見た目が不自然にならない ように処理を行っています。ただし、前提として、ウィンドウの高さが 画面全体の高さと一致している必要があります。

途中ですが、ここで一度テストプレイしてみましょう。アイテムを 選択した瞬間に操作不能になってしまいますが、ウィンドウがどのように 表示されるかは確認することができるでしょう。

## 場所テーブルの作成


テレポート先の場所データを定数として用意しましょう。

Ruby の配列は数値でも文字列でも自由に格納できるので、このような テーブルを直に記述するのに便利です。

```

TELEPORT_PLACES =
[
 [41, "場所Ａ", 1, 10, 10],
 [42, "場所Ｂ", 2, 25, 20],
 [43, "場所Ｃ", 3, 30, 15],
]
```



ここでは、スイッチ ID、テレポート先の名前、マップ ID、X 座標、Y 座標として使用することを意図しました。これらを格納した 配列を一単位とし、さらにそれが配列の中にあるという構造です。

スイッチ ID というのは、指定したスイッチが ON のときに その場所にテレポート可能にするという意味です。たとえば新しい町を 訪れたときなどにスイッチを ON にし、以後はその町にテレポートできる ようにするといった目的に使用します。

動作確認のため、テスト用プロジェクトで有効な場所を示すように 書き換えてください。サンプルとして三か所のデータを並べてあります が、もちろんいくつでも構いません。また、指定した ID のスイッチを ON にするイベントを作成しておいてください。

## テレポート位置の選択


テレポートウィンドウに、先ほど作成した場所データを表示できる ようにします。

Window_Teleport クラスの中に、次のコードを追加してください。

```

 def make_command_list
 TELEPORT_PLACES.each do |place|
 if $game_switches[place[0]]
 add_command(place[1], :teleport, true, place)
 end
 end
 end
```



配列の each メソッドによりループを行い、指定されたスイッチが ON であれば、該当する場所の名前をコマンドとして追加するようにして います。

add_command の 4 番目の引数には「拡張データ」を指定することが できます。拡張データとは、コマンドに付随する任意のデータの ことで、ここでは場所データ自体を持たせています。 3 番目の引数については次章で解説します。

## ハンドラの設定


最後に、決定とキャンセルのハンドリングを行います。

Scene_ItemBase クラスの start メソッドを次のように修正してください。

```

 alias xxx001_start start
 def start
 xxx001_start
 @teleport_window = Window_Teleport.new
 @teleport_window.set_handler(:teleport, method(:on_teleport))
 @teleport_window.set_handler(:cancel, method(:on_teleport_cancel))
 end
```



続いて on_teleport メソッドおよび on_teleport_cancel メソッドを実装します。

```

 def on_teleport
 place = @teleport_window.current_ext
 $game_player.reserve_transfer(place[2], place[3], place[4])
 SceneManager.goto(Scene_Map)
 end
 def on_teleport_cancel
 hide_sub_window(@teleport_window)
 end
```



current_ext メソッドは、現在選択されているコマンドに対応する 拡張データを取得するものです。ここでは場所データ自体を示している ので、そこからマップ ID と座標を取り出して場所移動を行います。

hide_sub_window メソッドは、show_sub_window メソッドの逆の処理を行います。キャンセルボタンが押されたときに ウィンドウを消し、アイテムの選択に戻るということです。

以上でテレポートの基本処理は完成です。実用的には、この他に テレポート自体を無効にする処理などが必要ですが、[脱出アイテムの作成](303_escape.md)ですでに解説済みなので ここでは省略します。ただし、脱出アイテムのスクリプトをそのまま 素材として残している方は、同じ個所を再定義することになります。 したがって、エイリアス名の衝突による競合に注意が必要です。

######
