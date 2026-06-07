# 景品交換所の作成


- [定数の定義](#constant)
- [コマンドの変更](#command)
- [所持金表示の変更](#money)
- [購入処理の変更](#buy)
- [終了処理の追加](#terminate)


ショップ画面の改造方法を解説します。

例として、変数の値を所持金とみなしてアイテムと交換できる 「景品交換所」を作成します。

## 定数の定義


これまでの例では、たとえば変数 7 番を参照する際に $game_variables[7] などと直接数字を指定してきました。 これはサンプルコードのわかりやすさを重視したためですが、 実際には、後から変更する可能性のある値は**定数**として定義するのが、より良い方法です。

定数については [Vocab モジュール](202_vocab.md)の章で解説したように、大文字で始まる識別子を定義するだけです。 慣習的に、全て大文字の名前がよく使われています。

今回は、スイッチ 20 番が ON のときに呼び出されたショップを「景品交換所」とみなし、変数 20 番の値を所持金とする仕様とします。

```

PRIZE_SHOP_SID = 20
PRIZE_SHOP_VID = 20
```



スイッチ ID を SID、変数 ID を VID と省略して命名しました。 これはクラス定義の外側に直に書いておけば OK です。特に複数の個所で同じ数値を使用する場合、このように 定数として定義しておけば、後で変更したくなったときに 変更漏れなどのミスが生じる危険がなくなります。

実装に入る前に、テストプレイのため、変数 20 番に適当な値を 入れ、スイッチ 20 番を ON にした状態でショップを呼び出すイベントを 作成しておいてください。

## コマンドの変更


まずは、ショップ画面の［購入する］コマンドの名前を［交換する］に 変更し、さらに［売却する］コマンドを消去します。

［購入する］などのコマンドを選択するウィンドウに対応する クラスは、Window_ShopCommand です。

```

class Window_ShopCommand
 alias xxx001_make_command_list make_command_list
 def make_command_list
 if $game_switches[PRIZE_SHOP_SID]
 add_command("交換する", :buy)
 add_command("やめる", :cancel)
 else
 xxx001_make_command_list
 end
 end
end
```



先ほど定義した定数を参照し、特定のスイッチが ON の場合に［交換する］と［やめる］を表示するようにしました。

add_command メソッドについては[あらすじ画面の作成](302_story.md)で 解説しましたから、内容は理解しやすいかと思います。 通常ショップの購入処理をそのまま使いたいので、シンボルは :buy のままとしています。

## 所持金表示の変更


所持金を表示するウィンドウで、お金の代わりに変数の値を 表示するようにします。これは Window_Gold クラスの value メソッドを再定義すれば可能です。

```

class Window_Gold
 alias xxx001_value value
 def value
 if $game_switches[PRIZE_SHOP_SID]
 $game_variables[PRIZE_SHOP_VID]
 else
 xxx001_value
 end
 end
end
```



同様に通貨単位を変更するため、currency_unit メソッドを 再定義します。ここではカジノのコインのようなものを想定して "枚" と表示させています。

```

class Window_Gold
 alias xxx001_currency_unit currency_unit
 def currency_unit
 if $game_switches[PRIZE_SHOP_SID]
 "枚"
 else
 xxx001_currency_unit
 end
 end
end
```



このウィンドウに表示されている値と通貨単位は、商品の選択や 個数入力のときにも自動的に使用されます。

## 購入処理の変更


実際に商品の購入を決定したときには、Scene_Shop クラスの do_buy メソッドが呼び出されます。これを再定義して、お金の代わりに 変数の値を減らすようにします。

```

class Scene_Shop
 alias xxx001_do_buy do_buy
 def do_buy(number)
 if $game_switches[PRIZE_SHOP_SID]
 $game_variables[PRIZE_SHOP_VID] -= number * buying_price
 $game_party.gain_item(@item, number)
 else
 xxx001_do_buy(number)
 end
 end
end
```



引数 number は購入個数、@item は購入するアイテム、buying_price はそのアイテムの値段です。

ここで呼び出している gain_item は Game_Party クラスのメソッド で、購入したアイテムを指定した数だけ増やす処理を行っています。

## 終了処理の追加


解読編の[シーンの管理](208_scene.md)にて解説したように、 シーンクラスには開始処理や終了処理を行うメソッドが用意されています。

今回は、終了処理を行う terminate メソッドを以下のように再定義します。

```

class Scene_Shop
 alias xxx001_terminate terminate
 def terminate
 xxx001_terminate
 $game_switches[PRIZE_SHOP_SID] = false
 end
end
```



これで、ショップ画面を閉じたとき、「景品交換所」識別用の スイッチを自動的に OFF にすることができます。

######
