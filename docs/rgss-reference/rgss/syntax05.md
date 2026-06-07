# 制御構造


- [条件分岐](#L000296)

 - [if](#L000297)
 - [if 修飾子](#L000298)
 - [unless](#L000299)
 - [unless 修飾子](#L000300)
 - [case](#L000301)

- [繰り返し](#L000302)

 - [while](#L000303)
 - [while 修飾子](#L000304)
 - [until](#L000305)
 - [until 修飾子](#L000306)
 - [for](#L000307)
 - [break](#L000308)
 - [next](#L000309)

- [例外処理](#L000312)

 - [raise](#L000313)
 - [begin](#L000314)
 - [rescue 修飾子](#L000315)

- [メソッド終了](#L000316)

 - [return](#L000317)



Ruby では (C 言語などとは異なり) 制御構造は式であって、何らかの値を返します。

Ruby は C 言語や Perl から引き継いだ制御構造を持ちますが、 その他に[イテレータ](syntax06.md#L000323)というループ抽象化の機 能があります。イテレータは繰り返しを始めとする制御構造をユーザーが定義する事が できるものです。

## 条件分岐


### if


例:

```

if age >= 12 then
 print "adult fee\n"
else
 print "child fee\n"
end
gender = if foo.gender == "male" then "male" else "female" end
```



文法:

```

if 式 [then]
 式 ...
[elsif 式 [then]
 式 ... ]
...
[else
 式 ... ]
end
```



条件式を評価した結果が真であるとき、then 以下の式を評価します。 if の条件式が偽であれば elsif の条件を評価します。 elsif 節は複数指定でき、全ての if および elsif の条件式が偽であったとき else 節があればその式が評価されます。

if 式は、条件が成立した節 (あるいは else 節) の最後に評価した式の結果を 返します。else 節がなくいずれの条件も成り立たなければ nil を返します。

Ruby では false または nil だけが偽で、それ以外は 0 や空文字列も含め 全て真です。

Ruby では if を繋げるのは elsif であり、else if でも elif でもないことに 注意してください。

### if 修飾子


例:

```

print "debug\n" if $DEBUG
```



文法:

```

式 if 式
```



右辺の条件が成立するときに、左辺の式を評価してその結果を返します。 条件が成立しなければ nil を返します。

### unless


例:

```

unless baby?
 feed_meat
else
 feed_milk
end
```



文法:

```

unless 式 [then]
 式 ...
[else
 式 ... ]
end
```



unless は if と反対で、条件式が 偽のときに then 以下の式を評価します。unless 式に elsif を指定することはできません。

### unless 修飾子


例:

```

print "stop\n" unless valid(passwd)
```



文法:

```

式 unless 式
```



右辺の条件が成立しないときに、左辺の式を評価してその結果を返します。 条件が成立しなければ nil を返します。

### case


例:

```

case $age
when 0 .. 2
 "baby"
when 3 .. 6
 "little child"
when 7 .. 12
 "child"
when 13 .. 18
 "youth"
else
 "adult"
end
```



文法:

```

case 式
[when 式 [, 式] ... [then]
 式 ..]..
[else
 式 ..]
end
```



case はひとつの式に対する一致判定による分岐を行います。when 節で指定 された値と最初の式を評価した結果とを演算子 === を用いて比較して、一致する 場合には when 節の本体を評価します。

case は、条件が成立した when 節 (あるいは else 節) の最後に評価した式の 結果を返します。いずれの条件も成り立たなければ nil を返します。

## 繰り返し


### while


例:

```

ary = [0,2,4,8,16,32,64,128,256,512,1024]
i = 0
while i < ary.length
 print ary[i]
 i += 1
end
```



文法:

```

while 式 [do]
 ...
end
```



式を評価した値が真の間、本体を繰り返し実行します。

while は nil を返します。また、引数を伴った break により while 式の 戻り値をその値にすることもできます。

### while 修飾子


例:

```

sleep(60) while io_not_ready?
```



文法:

```

式 while 式
```



右辺の式を評価した値が真の間、左辺を繰り返し実行します。左辺の式が begin である場合には、それを最初に一回評価してから繰り返します。

while 修飾した式は nil を返します。また、引数を伴った break により while 修飾した式の戻り値をその値にすることもできます。

### until


例:

```

until f.eof?
 print f.gets
end
```



文法:

```

until 式 [do]
 ...
end
```



式を評価した値が真になるまで、本体を繰り返して実行します。

until は nil を返します。また、引数を伴った break により until 式の 戻り値をその値にすることもできます。

### until 修飾子


例:

```

print(f.gets) until f.eof?
```



文法:

```

式 until 式
```



右辺の式を評価した値が真になるまで、左辺を繰り返して実行します。左辺の式が begin である場合には、それを最初に一回評価してから繰り返します。

until 修飾した式は nil を返します。また、引数を伴った break により until 修飾した式の戻り値をその値にすることもできます。

### for


例:

```

for i in [1, 2, 3]
 print i*2, "\n"
end
```



文法:

```

for lhs ... in 式 [do]
 式 ..
end
```



式を評価した結果のオブジェクトの各要素に対して本体を繰り返し て実行します。これは以下の式とほぼ同じです。

```

(式).each '{' '|' lhs..'|' 式 .. '}'
```



「ほぼ」というのは、do ... end または { } によるブロックは 新しいローカル変数の有効範囲を導入するのに対し、for はローカル変数の スコープに影響を及ぼさない点が異なるからです。

for は、in に指定したオブジェクトの each メソッドの戻り値を返します。

### break


例:

```

i = 0
while i < 3
 print i, "\n"
 break
end
```



文法:

```

break [式]
```



break はもっとも内側のループを脱出します。ループとは

- while
- until
- for
- イテレータ


のいずれかを指します。C 言語と異なり、break はループを脱出する作用 だけを持ち、case を抜ける作用は持ちません。

break によりループを抜けた for やイテレータは nil を返します。 ただし、引数を指定した場合はループの戻り値はその引数になります。

### next


例:

```

str.each_line do |line|
 next if line.empty?
 print line
end
```



文法:

```

next [式]
```



next はもっとも内側のループの次の繰り返しにジャンプ します。[イテレータ](syntax06.md#L000323)で は、[yield](syntax06.md#L000324) 呼び出しの脱出になります。

next により抜けた yield は nil を返します。ただし、引数を指定した 場合、yield の戻り値はその引数になります。

## 例外処理


### raise


例:

```

raise
raise "you lose"
raise SyntaxError.new("invalid syntax")
raise SyntaxError, "invalid syntax"
```



文法:

```

raise
raise message
raise exception
raise error_type, message
```



例外を発生させます。第一の形式では直前の例外を再発生させます。 第二の形式 (引数が文字列の場合) では、その文字列をメッセージとする [RuntimeError](s_exceptions.md#RuntimeError) 例外を発生させます。 第三の形式 (引数が例外オブジェクトの場合) では、その例外を発生させます。 第四の形式では第一引数で指定された例外を、第二引数をメッセージとして発生 させます。

発生した例外は begin 式の rescue 節で捕らえることができます。

[raise](s_functions.md#L000388) は実際には Ruby の予約語では なく、組み込み関数です。

### begin


例:

```

begin
 do_something
rescue
 recover
ensure
 must_to_do
end
```



文法:

```

begin
 式 ..
[rescue [error_type,..] [then]
 式 ..]..
[ensure
 式 ..]
end
```



本体の実行中に例外が発生した場合、rescue 節 (複数指定できます) が 与えられていれば例外を捕捉できます。発生した例外と一致する rescue 節が存在するときには rescue 節の本体が実行されます。 発生した例外は、組み込み変数 [$!](s_variables.md#L000437) を使って 参照することができます。

*error_type* が省略されたときは [StandardError](s_exceptions.md#StandardError) の サブクラスである全ての例外を捕捉します。Ruby のほとんどの組み込み例外は [StandardError](s_exceptions.md#StandardError) のサブクラス です。[組み込み例外クラス](s_exceptions.md)を参照してください。

rescue では *error_type* は通常の引数と同じように評価され、 そのいずれかが一致すれば本体が実行されます。*error_type* を評価し た値がクラスやモジュールでない場合には例外 [TypeError](s_exceptions.md#TypeError) が発生します。

ensure 節が存在するときは begin 式を終了する直前に必ず ensure 節の 本体を評価します。

begin は、本体または rescue 節で最後に評価した式の結果を返します。

### rescue 修飾子


例:

```

File.open("file") rescue print "can't open\n"
```



文法:

```

式1 rescue 式2
```



式 1 で例外が発生したとき、式 2 を評価します。 捕捉する例外クラスを指定することはできません (つま り、[StandardError](s_exceptions.md#StandardError) 例外クラスの サブクラスだけしか捕捉できません) 。

rescue 修飾子を伴う式は、例外が発生しなければ式 1、例外が発生すれば式 2 の結果を返します。

## メソッド終了


### return


例:

```

return
return 12
return 1,2,3
```



文法:

```

return [式[',' 式 ... ]]
```



式の値を戻り値としてメソッドの実行を終了します。式が 2 つ以上 与えられたときには、それらを要素とする配列をメソッドの戻り値と します。式が省略された場合には nil を戻り値とします。

######
