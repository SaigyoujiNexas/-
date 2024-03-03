# DSL

## 带接收者的函数字面量

```kotlin
publix inline fun<T> T.apply(block: T.() -> Unit) : T {
    block()
    return this
}
```

如此的编程范式， 即可写出领域特定函数(DSL),  暴露接收者的函数和特性， 以便使用lambda表达式来进行读取与配置。

# 函数式编程

函数式编程范式主要依赖于高阶函数调用(以函数为参数或返回函数)返回的数据。

## 函数类别

函数式应用通常由三大类： transform, filter, combine, 每类函数都针对集合数据类型设计， 即可以组合多个简单函数构建复杂的计算

## 变换

变换函数会遍历集合内容， 以一个值参的形式传入的变换器函数， 变换每一个元素

```kotlin
fun main(){
    val animals = listOf("zebra", "giraffe", "elephant", "rat")
    val babies = animals
    .map{animal -> "A baby $animal"}
    .map{baby -> "$baby, with the cutest little tail ever!"}
    println(animals);
    println(babies);
}
```

 map变换函数并没有导致原始集合内容改变

map返回的集合个数和输入集合的个数必须相同， 不过返回的新集合的元素类型可以不同

### flatmap

flatmap函数操作一个集合的集合

```kotlin
 fun main(){
     val result = listOf(listOf(1, 2, 3), listOf(4, 5, 6)).flatMap{it}
     println(result)
 }
```



## 过滤

过滤函数接收一个predicate函数， 返回true加入新集合中， 否则移出新集合。

```kotlin
fun main()
{
    val result = listOf("Jack", "jimmy", "Rose", "Tom")
        .filter { it.contains("J") }
    println(result)
}
```

```kotlin
fun main()
{
    val items  = listOf(
        listOf("red apple", "green apple", "blue apple"),
        listOf("red fish", "blue fish"),
        listOf("yellow banana", "green banana")
    )
    val redItem = items.flatMap { it.filter{it.contains("red")} }.apply { println(this) }
}
```

```kotlin
fun main()
{
    val numbers= listOf(7, 4, 8, 4, 3, 22, 18, 11)
    val primes = numbers.filter { number ->
        (2 until number)
            .map { number % it }.
            none { it == 0 } }
    println(primes)
}
```



## 合并

### zip

zip合并函数来合并两个集合, 形成一个键值对

```kotlin
fun main(){
    val employees = listOf("Jack", "Jason", "Tommy")
    val ages = listOf(18, 20, 30)
    
    val map = employees.zip(ages).toMap()
    println(map["Jack"])
}
```

### fold

fold合并函数接收一个初始累加器值， 随后根据匿名函数的结果更新

```kotlin
fun main(){
    val foldedValue = listOf(1, 2, 3, 4).fold(0) { acc, x ->
        println("Accumulator value: $acc")
        acc + x * 3
    }
    println("Final value: $foldedValue")
}
```



# 序列

List, Map, Set 这几个集合类型统称为**及早集合(eager collection)**， 这些集合的任何一个实例在创建后， 其包含的元素都会被加入并允许访问



## 惰性集合

**lazy collection** 用于包含大量元素的集合时， 性能表现优异， 因为**集合元素是按需产生的**

, Kotlin 内置惰性集合Sequence, 序列值可能有无限多

## generateSequence

```kotlin
fun main(){
    fun Int.isPrime(): Boolean{
        (2 until this).map{
            if (this % it == 0)
            return false
        }
        return true
    }
    //In fact to size will never satisfy 1000
    val toList = (1..5000).toList.filter{it.isPrime()}.take(1000)
    
}
```

使用Sequence

```kotlin
fun main(){
    
    val oneTousandPrimes = generateSequence(2) {value -> value + 1}.filter{it.isPrime()}.take(1000)
        println(oneTousandPrimes.toList().size)
}
```





