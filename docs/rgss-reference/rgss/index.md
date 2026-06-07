# RGSS リファレンス


RGSS (Ruby Game Scripting System) は、オブジェクト指向スクリプト言語 Ruby で Windows® 用 2D ゲームを開発するためのシステムです。

## 目次


- [RGSS の仕様](rgss.md)
- [Ruby の文法](syntax00.md)

 - [字句構造と式](syntax01.md)
 - [変数と定数](syntax02.md)
 - [リテラル](syntax03.md)
 - [演算子式](syntax04.md)
 - [制御構造](syntax05.md)
 - [メソッド呼び出し](syntax06.md)
 - [クラスとメソッドの定義](syntax07.md)

- [標準ライブラリ](s_index.md)

 - [組み込み関数](s_functions.md)
 - [組み込み変数](s_variables.md)
 - [組み込みクラス](s_classes.md)
 - [組み込みモジュール](s_modules.md)
 - [組み込み例外クラス](s_exceptions.md)

- [ゲームライブラリ](g_index.md)

 - [RGSS 組み込み関数](g_functions.md)
 - [RGSS 組み込みクラス](g_classes.md)
 - [RGSS 組み込みモジュール](g_modules.md)
 - [VX Ace データ構造](g_rpg_data.md)

- [付録](appendix00.md)

 - [正規表現](appendix01.md)
 - [sprintf フォーマット](appendix02.md)



## 本ドキュメントについて


本ドキュメントは、Ruby のリファレンスマニュアルから RGSS を使用する上で 最低限必要な情報を抜粋し、RGSS の独自仕様に関する解説を加えて再編集したもの です。基本的に Ruby 1.8 対応の旧版を元にしているため、RGSS3 で採用している Ruby 1.9 の仕様とは細部が異なる場合があります。

オリジナルの Ruby、および本ドキュメントの原文は Ruby の公式ページ [ http://www.ruby-lang.org/](http://www.ruby-lang.org/) から入手可能です。Ruby に関してより詳細な情報 が必要な方は、こちらを参照してください。

## ユーザーサポートについて


スクリプトエディタの編集によるゲーム作成方法、ならびにスクリプトエディタの編集によって引き起こされた不具合につきましては、サポートいたしかねます。また、スクリプト (Ruby・RGSS3) についても、弊社および Ruby 開発者のまつもと ゆきひろ氏はサポートの義務を負いません。編集する際には、十分に Ruby・RGSS3 を理解したうえでご利用ください。

Ruby の公式サイト、その他 Ruby の情報・支援サイト等をご利用の際は、ある程度の知識を身につけたうえで、サイト運営の関係者および他の利用者の迷惑にならない態度で臨むよう心がけましょう。

######
