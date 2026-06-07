# Fixnum


マシンのポインタのサイズに収まる長さの固定長整数。ほとんどのマシンでは 31 ビット幅です。演算の結果が Fixnum の範囲を越えたときには自動的 に [Bignum](sc_bignum.md) に拡張されます。

## スーパークラス


- [Integer](sc_integer.md)


## メソッド



### id2name



[Symbol](sc_symbol.md) オブジェクトの整数値 ([Symbol#to_i](c_symbol.md#L001482) で得られます) に対応する文字列を返します。整数に対応するシンボルが 存在しないときには nil を返します。

### to_sym



オブジェクトの整数値 self に対応する [Symbol](sc_symbol.md) オブジェクトを返します。整数に対応するシンボルが存在しないときには nil を返します。

######
