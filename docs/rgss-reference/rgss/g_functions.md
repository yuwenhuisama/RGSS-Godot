# RGSS 組み込み関数


RGSS には以下の組み込み関数が定義されています。


### rgss_main { ... } (RGSS3)



与えられたブロックを一度だけ評価します。

ブロックの中では F12 キーによるリセットを捕捉し、 リセットされた場合は先頭に戻ります。

```

rgss_main { SceneManager.run }
```



### rgss_stop (RGSS3)



スクリプトの実行を停止し、画面の更新だけを繰り返します。[スクリプト入門](../intro/index.md)で使用するために定義されています。

以下と等価です。

```

loop { Graphics.update }
```



### load_data(*filename*)



*filename* で指定されるデータファイルを読み込み、 オブジェクトを復元します。

```

$data_actors = load_data("Data/Actors.rvdata2")
```

 この関数は基本的に

```

File.open(filename, "rb") { |f|
 obj = Marshal.load(f)
}
```



と同じですが、[暗号化アーカイブ](rgss.md#encryption_archive)の 内部にあるファイルを読み込むことができる点が異なります。

### save_data(*obj*, *filename*)



オブジェクト *obj* を *filename* で指定される データファイルに書き込みます。

```

save_data($data_actors, "Data/Actors.rvdata2")
```

 この関数は

```

File.open(filename, "wb") { |f|
 Marshal.dump(obj, f)
}
```



と同じです。

### msgbox(*arg*[, ...]) (RGSS3)



引数をメッセージボックスに出力します。 文字列以外のオブジェクトが引数として与えられた場合には、 当該オブジェクトを to_s メソッドにより文字列に変換 してから出力します。

nil を返します。

### msgbox_p(*obj*, [*obj2*, ...]) (RGSS3)



*obj* を人間に読みやすい形でメッセージボックスに出力します。 以下のコードと同じです ([Object#inspect](sc_object.md#L000572) 参照) 。

```

msgbox obj.inspect, "\n", obj2.inspect, "\n", ...
```



nil を返します。

######
