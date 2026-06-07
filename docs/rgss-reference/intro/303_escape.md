# 脱出アイテムの作成


- [アイテムデータの作成](#data)
- [アイテムの使用処理](#use)
- [シーン遷移](#scene)
- [場所移動](#transfer)
- [アイテムの無効化](#disable)


メニュー画面からアイテムやスキルを使用したときに 独自の処理を行う方法を解説します。

例として、ダンジョンなどから脱出し、入口へ瞬間移動する アイテムを作成します。

## アイテムデータの作成


スクリプトを作成する前に、データベースを開き、脱出アイテムのデータを 設定します。適当な位置に新しい項目を作成してください。

効果範囲は［なし］、使用可能時は［メニューのみ］とし、メモに <ESCAPE> と入力しておきましょう (<>を含む) 。

独自の効果を持つアイテムやスキルを作成する場合、 設定項目［メモ］を利用すると便利です。スクリプトにて、メモに特定の キーワードが含まれているか否かによって判定することで、名前や ID で判定するよりも汎用性が増すからです。今回は <ESCAPE> というキーワードが含まれているとき、脱出アイテムとみなします。

データベースの設定が終わったら、イベントコマンド［アイテムの増減］を 含んだイベントを作成し、そのアイテムをテストプレイですぐに使える状態に しておいてください。

## アイテムの使用処理


メニュー画面からアイテムやスキルを使用したとき、その処理を行うのは Scene_ItemBase クラスの use_item メソッドです (item という名前が付いていますが、スキルの処理も含みます) 。 最初のステップとして、次のように再定義してみましょう。

```

class Scene_ItemBase
 alias xxx001_use_item use_item
 def use_item
 xxx001_use_item
 use_escape_item if item.note.include?("<ESCAPE>")
 end
 def use_escape_item
 print "脱出！\n"
 end
end
```



ここでは、使用されたアイテムの［メモ］に <ESCAPE> という文字列が含まれていれば use_escape_item メソッドを呼び出すという処理を追加しました。

```

 use_escape_item if item.note.include?("<ESCAPE>")
```



item というのは、使用されたアイテムのオブジェクト、つまり [RPG::Item](../rgss/gc_rpg_item.md) や [RPG::Skill](../rgss/gc_rpg_skill.md) のインスタンスを 返すメソッドです (これは Scene_ItemBase クラスではなく、継承先の Scene_Item および Scene_Skill クラスで定義されています) 。note は［メモ］に対応する文字列です。文字列クラス [String](../rgss/sc_string.md) の include? メソッドは、特定の部分文字列が含まれるかを判定します。

use_escape_item メソッドの内容としては、ダミーの処理としてひとまず "脱出！" という文字列をコンソールに出力するようにしています。

```

 def use_escape_item
 print "脱出！\n"
 end
```



実際にテストプレイを行って、先ほど作成した脱出アイテムを使用し、 メソッドが正常に呼び出されることを確認してから次に進みましょう。

## シーン遷移


アイテムを使用したとき、自動的にマップ画面に戻るように することができます。use_escape_item メソッドを次のように書き換えてください。前章では call メソッドを使用しましたが、呼び出し元の画面に戻る必要がないときには goto メソッドを使用します。

```

 def use_escape_item
 SceneManager.goto(Scene_Map)
 end
```



Scene_Map は、その名の通りマップ画面に対応するシーンクラス です。SceneManager モジュールの goto メソッドをこのように呼び出す ことで、アイテムを使用したとき、自動的にマップ画面に戻るように することができます。

## 場所移動


プレイヤーに対応するクラス Game_Player には、場所移動を予約する reserve_transfer メソッドがあります。

```

 def use_escape_item
 $game_player.reserve_transfer(1, 10, 8)
 SceneManager.goto(Scene_Map)
 end
```



引数の順序は、マップ ID、X 座標、Y 座標の順です。上記の例では マップ ID = 1、X = 10、Y = 8 の地点への場所移動を指示しています。このように、まずは適当な地点を 決め打ちで指定し、正常に移動できるか実験してみてください。

場所移動の動作が確認できたら、ゲーム内の変数で移動先を設定 できるように変更します。

```

 def use_escape_item
 m = $game_variables[21]
 x = $game_variables[22]
 y = $game_variables[23]
 $game_player.reserve_transfer(m, x, y)
 SceneManager.goto(Scene_Map)
 end
```



例では変数 21 ～ 23 番を移動先として使用しています。 もちろん、使用する変数番号はこの通りでなくても構いません。

## アイテムの無効化


脱出アイテムは、ダンジョンの外では使用できないようにしたいことが 多いでしょう。アイテムの使用可能判定を変更し、マップ ID を格納する変数 21 番の値が 0 のときには選択できないようにします。

```

class Game_BattlerBase
 alias xxx001_usable_item_conditions_met? usable_item_conditions_met?
 def usable_item_conditions_met?(item)
 if item.note.include?("<ESCAPE>") && $game_variables[21] == 0
 false
 else
 xxx001_usable_item_conditions_met?(item)
 end
 end
end
```



アイテムやスキルの使用可能判定は、主に Game_BattlerBase クラスが受け持っています。ここでは usable_item_conditions_met? というメソッドを再定義します。コメントにも書かれている通り、これは スキルとアイテムの共通使用可能条件をチェックするメソッドです。true を返せば使用可能、false を返せば使用不可能ということです。

使用可能判定の全体像を把握したい場合は、usable? メソッドから辿って解読を試みると良いでしょう。

######
