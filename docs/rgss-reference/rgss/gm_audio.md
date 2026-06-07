# Audio


ミュージック、サウンドにかかわる処理を行うモジュール。

## モジュールメソッド



### Audio.setup_midi (RGSS3)



DirectMusic による MIDI 演奏の準備を行います。

RGSS2 において起動時に行っていた処理を、任意のタイミングで 実行できるようにメソッド化したものです。

このメソッドを呼んでいなくても MIDI 演奏はできますが、Windows Vista 以降において初回の演奏時に 1 ～ 2 秒の遅延が生じます。

### Audio.bgm_play(*filename*[, *volume*[, *pitch*[, *pos*]]]) (RGSS3)



BGM の演奏を開始します。順にファイル名、ボリューム、ピッチ、再生開始位置を指定します。

再生開始位置 (RGSS3) は ogg または wav の場合のみ有効です。

[RGSS-RTP](rgss.md#rgss_rtp) に含まれるファイルも 自動的に探します。拡張子は省略可能です。

### Audio.bgm_stop



BGM の演奏を停止します。

### Audio.bgm_fade(*time*)



BGM のフェードアウトを開始します。*time* は、 フェードアウトにかける時間をミリ秒単位で指定します。

### Audio.bgm_pos (RGSS3)



BGM の再生位置を取得します。ogg または wav の場合のみ有効です。有効でない場合は 0 を返します。

### Audio.bgs_play(*filename*[, *volume*[, *pitch*[, *pos*]]]) (RGSS3)



BGS の演奏を開始します。順にファイル名、ボリューム、ピッチ、再生開始位置を指定します。

再生開始位置 (RGSS3) は ogg または wav の場合のみ有効です。

[RGSS-RTP](rgss.md#rgss_rtp) に含まれるファイルも 自動的に探します。拡張子は省略可能です。

### Audio.bgs_stop



BGS の演奏を停止します。

### Audio.bgs_fade(*time*)



BGS のフェードアウトを開始します。*time* は、 フェードアウトにかける時間をミリ秒単位で指定します。

### Audio.bgs_pos (RGSS3)



BGS の再生位置を取得します。ogg または wav の場合のみ有効です。有効でない場合は 0 を返します。

### Audio.me_play(*filename*[, *volume*[, *pitch*]])



ME の演奏を開始します。順にファイル名、ボリューム、ピッチを指定します。

[RGSS-RTP](rgss.md#rgss_rtp) に含まれるファイルも 自動的に探します。拡張子は省略可能です。

ME の演奏中は BGM が一時停止します。BGM が復帰するタイミングは RGSS1 とはやや異なります。

### Audio.me_stop



ME の演奏を停止します。

### Audio.me_fade(*time*)



ME のフェードアウトを開始します。*time* は、 フェードアウトにかける時間をミリ秒単位で指定します。

### Audio.se_play(*filename*[, *volume*[, *pitch*]])



SE の演奏を開始します。順にファイル名、ボリューム、ピッチを指定します。

[RGSS-RTP](rgss.md#rgss_rtp) に含まれるファイルも 自動的に探します。拡張子は省略可能です。

きわめて短期間に同じ SE を演奏しようとした場合、音割れを防止するため、 自動的に間引き処理を行います。

### Audio.se_stop



すべての SE の演奏を停止します。

######
