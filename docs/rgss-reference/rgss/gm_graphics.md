# Graphics


グラフィック全体にかかわる処理を行うモジュール。

## モジュールメソッド



### Graphics.update



ゲーム画面を更新し、時間を 1 フレーム進めます。 このメソッドは必ず定期的に呼び出す必要があります。

```

loop do
 Graphics.update
 Input.update
 do_something
end
```



### Graphics.wait(*duration*)



指定されたフレーム数だけウェイトをかけます。以下と等価です。

```

duration.times do
 Graphics.update
end
```



### Graphics.fadeout(*duration*)



画面のフェードアウトを行います。

*duration* はフェードアウトにかけるフレーム数です。

### Graphics.fadein(*duration*)



画面のフェードインを行います。

*duration* はフェードインにかけるフレーム数です。

### Graphics.freeze



トランジションの準備として、現在の画面を固定します。

これ以後 transition メソッドを呼び出すまでは、一切の画面の書き換えが 禁止されます。

### Graphics.transition([*duration*[, *filename*[, *vague*]]])



freeze メソッドで固定した画面から現在の画面へのトランジションを行います。

*duration* はトランジションにかけるフレーム数です。 省略時は 10 になります。

*filename* はトランジション グラフィックのファイル名を指定します (指定しない場合は通常のフェードになります) 。[RGSS-RTP](rgss.md#rgss_rtp)、[暗号化アーカイブ](rgss.md#encryption_archive)に含まれるファイルも自動的に 探します。拡張子は省略可能です。

*vague* は転送元と転送先の境界のあいまいさで、値が大きいほど あいまいになります。省略時は 40 になります。

### Graphics.snap_to_bitmap



現在のゲーム画面のイメージをビットマップ オブジェクトとして取得します。

freeze メソッドによる固定とは関係なく、その時点で本来表示されているべき グラフィックが反映されます。

作成したビットマップは、不要になりしだい解放する必要があります。

### Graphics.frame_reset



画面の更新タイミングをリセットします。時間のかかる処理の後に このメソッドを呼ぶことで、極端なフレームスキップが発生しないようにする ことができます。

### Graphics.width


### Graphics.height



ゲーム画面の幅および高さを取得します。

通常はそれぞれ 544、416 を返します。

### Graphics.resize_screen(*width*, *height*)



ゲーム画面のサイズを変更します。

width と height に幅および高さを 640×480 までの範囲で指定 します。

### Graphics.play_movie(*filename*) (RGSS3)



filename で指定されたムービーの再生を行います。

再生終了を待ってから処理を返します。

## モジュールプロパティ



### Graphics.frame_rate



1 秒間に画面を更新する回数です。値が大きいほど多くの CPU パワーが必要に なります。通常は 60 です。

このプロパティを変更することは推奨されませんが、変更する場合 は 10 ～ 120 の範囲で指定します。範囲外の値は自動で修正されます。

### Graphics.frame_count



画面の更新回数のカウントです。ゲーム開始時にこのプロパティを 0 に設定して おくと、frame_rate プロパティの値で割ることで、ゲームのプレイ時間 (秒数) が 算出できます。

### Graphics.brightness



画面の明るさです。0 ～ 255 の範囲の値を取ります。 fadeout、fadein、transition メソッドは、内部で必要に応じてこの値を 変更しています。

######
