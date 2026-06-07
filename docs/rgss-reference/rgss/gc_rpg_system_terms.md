# RPG::System::Terms


用語のデータクラス。

## スーパークラス


- [Object](sc_object.md)


## 参照元


- [RPG::System](gc_rpg_system.md)


## 属性



### basic


基本ステータス。以下を添字とする文字列の配列です。

- 0 : レベル
- 1 : レベル (短)
- 2 : HP
- 3 : HP (短)
- 4 : MP
- 5 : MP (短)
- 6 : TP
- 7 : TP (短)


### params


能力値。以下を添字とする文字列の配列です。

- 0 : 最大HP
- 1 : 最大MP
- 2 : 攻撃力
- 3 : 防御力
- 4 : 魔法力
- 5 : 魔法防御
- 6 : 敏捷性
- 7 : 運


### etypes


装備タイプ。以下を添字とする文字列の配列です。

- 0 : 武器
- 1 : 盾
- 2 : 頭
- 3 : 身体
- 4 : 装飾品


### commands


コマンド。以下を添字とする文字列の配列です。

- 0 : 戦う
- 1 : 逃げる
- 2 : 攻撃
- 3 : 防御
- 4 : アイテム
- 5 : スキル
- 6 : 装備
- 7 : ステータス
- 8 : 並び替え
- 9 : セーブ
- 10 : ゲーム終了
- 11 : (欠番)
- 12 : 武器
- 13 : 防具
- 14 : 大事なもの
- 15 : 装備変更
- 16 : 最強装備
- 17 : 全て外す
- 18 : ニューゲーム
- 19 : コンティニュー
- 20 : シャットダウン
- 21 : タイトルへ
- 22 : やめる


## 定義


```

class RPG::System::Terms
 def initialize
 @basic = Array.new(8) {''}
 @params = Array.new(8) {''}
 @etypes = Array.new(5) {''}
 @commands = Array.new(23) {''}
 end
 attr_accessor :basic
 attr_accessor :params
 attr_accessor :etypes
 attr_accessor :commands
end
```



######
