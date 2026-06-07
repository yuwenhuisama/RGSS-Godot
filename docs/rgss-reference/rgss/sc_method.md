# Method


[Object#method](sc_object.md#method) によりオブジェクト化されたメソッドオブジェクトのクラスです。 メソッドの実体 (名前でなく) とレシーバの組を封入します。[Proc](sc_proc.md) オブジェクトと違ってコンテキストを保持しません。

[Proc](sc_proc.md) との差… Method は取り出しの対象であるメソッドが なければ作れませんが、Proc は準備なしに作れます。その点から Proc は使い捨てに向き、Method は何度も繰り返し生成する 場合に向くと言えます。また内包するコードの大きさという点では Proc は小規模、Method は大規模コードに向くと言えます。

```

class Foo
 def foo(arg)
 "foo called with arg #{arg}"
 end
end
 
m = Foo.new.method(:foo)
 
p m # => #<Method: Foo#foo>
p m.call(1) # => "foo called with arg 1"
```



## スーパークラス


- [Object](sc_object.md)


## メソッド



### call(*arg* ... )


### call(*arg* ... ) { ... }



メソッドオブジェクトに封入されているメソッドを起動します。 引数やブロックはそのままメソッドに渡されます。

######
