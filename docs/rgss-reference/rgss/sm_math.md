# Math


浮動小数点演算をサポートするモジュール。

## モジュール関数



### Math.acos(*x*)


### Math.asin(*x*)


### Math.atan(*x*)



*x* の逆三角関数の値をラジアンで返します。

返される値の範囲はそれぞれ [0, + π] 、[-π/2, +π/2] 、 (-π/2, +π/2) です。

acos(x), asin(x) では *x* は -1.0 <= *x* <= 1 の範囲内でな ければなりません (普通、NaN を返します) 。

acos(), asin() は範囲外の引数に対して、例 外 [Errno::EDOM](s_exceptions.md#Errno) が発生します。

### Math.atan2(*y*, *x*)



*y*/*x* のアークタンジェントを [-π, π] の範囲で返します。

### Math.acosh(*x*)


### Math.asinh(*x*)


### Math.atanh(*x*)



*x* の逆双曲線関数の値を返します。

```

asinh(x) = log(x + sqrt(x * x + 1))
acosh(x) = log(x + sqrt(x * x - 1)) [x >= 1]
atanh(x) = log((1+x)/(1-x)) / 2 [-1 < x < 1]
```



acosh(x) では *x* は*x* >= 1 の範囲内でなければなりません (普通、例外 [Errno::EDOM](s_exceptions.md#Errno) が発生します) 。

atanh(x) では *x* は -1.0 < *x* < 1 の範囲内でなければな りません (普通、例外 [Errno::EDOM](s_exceptions.md#Errno) が発生します) 。

### Math.cos(*x*)


### Math.sin(*x*)


### Math.tan(*x*)



ラジアンで表された *x* の三角関数の値を [-1, 1] の範囲で 返します。

### Math.cosh(*x*)


### Math.sinh(*x*)


### Math.tanh(*x*)



*x* の双曲線関数の値を返します。

```

cosh(x) = (exp(x) + exp(-x)) / 2
sinh(x) = (exp(x) - exp(-x)) / 2
tanh(x) = sinh(x) / cosh(x)
```



### Math.erf(*x*)


### Math.erfc(*x*)



x の誤差関数 (erf) 、相補誤差関数 (erfc) の値を返します。

### Math.exp(*x*)



*x* の指数関数の値を返します。

### Math.frexp(*x*)



実数 *x* の指数部と仮数部を返します。

### Math.hypot(*x*, *y*)



sqrt(x*x + y*y) を返します。

### Math.ldexp(*x*, *exp*)



実数 *x* に 2 の *exp* 乗をかけた数を返します。

### Math.log(*x*)



*x* の自然対数を返します。

*x* は正の値でなければなりません (普通、負の値に対して NaN を 0 に対して -Infinity を返します) 。

範囲外の引数に対して、負の場合に例外 [Errno::EDOM](s_exceptions.md#Errno) が 0 の場合に [Errno::ERANGE](s_exceptions.md#Errno) が発生します。

### Math.log10(*x*)



*x* の常用対数を返します。

*x* は正の値でなければなりません (普通、負の値に対して NaN を 0 に対して -Infinity を返します) 。

範囲外の引数に対して、負の場合に例外 [Errno::EDOM](s_exceptions.md#Errno) が 0 の場合に [Errno::ERANGE](s_exceptions.md#Errno) が発生します。

### Math.sqrt(*x*)



*x* の平方根を返します。*x* の値が負である>ときには例外 [ArgumentError](s_exceptions.md#ArgumentError) が発生します。

普通、x が負の場合、例外 [Errno::EDOM](s_exceptions.md#Errno) が発生します。

## 定数



### E



自然対数の底

```

p Math::E
# => 2.718281828
```



### PI



円周率

```

p Math::PI
# => 3.141592654
```



######
