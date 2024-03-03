# Kotlin Flow

```kotlin
fun simple(): List<Int> = listOf(1, 2, 3)

fun main(){
    simple().forEach{value -> println(value)}
}
```

![image-20220708114941032](https://s2.loli.net/2022/07/08/v3PTQ2kbofyEZJ6.png)

对于耗时操作， 可以使用sequence来表示这些数字。

```kotlin
fun simple(): Sequence<Int> = sequence{
    for(in in 1..3){
        Thread.sleep(100)
        yield(i)
    }
}
fun main(){
    simple().forEach{value -> println(value)}
}
```

打印每个数字会间隔100ms，

## suspend function

使用suspend来让主线程不阻塞并返回结果

```kotlin
suspend fun simple(): List<Int>{
    delay(1000)
    return listOf(1, 2, 3)
}
fun main() = runBlocking<Unit>{
    simple().forEach{value -> println(value)}
}

```

在1秒后打印出结果。

## Flows

使用Flow可以实现像是Sequence的调用。

```kotlin
fun simple(): Flow<Int> = flow{
    for(i in 1..3){
        delay(1000)
        emit(i)
    }
}
fun main() = runBlocking<Unit>{
    //launch a concurrent coroutine to check if the main thread is blocked
    launch{
        for(k in 1..3){
            println("I am not blocked $k")
            delay(1000)
        }
    }
    //collect the flow
    simple().collect{value -> println(value)}
}
```

simple 函数不再需要suspend标签；

发送数据使用emit函数

收集数据使用collect

## Flows are cold

```kotlin
fun simple(): Flow<Int> = flow{
    println("Flow started")
    for(i in 1..3){
        delay(100)
        emit(i)
    }
}
fun main() = runBlocking<Unit>{
    println("Calling simple function...")
    val flow = simple()
    println("Calling collect...")
    flow.collect{value -> println(value)}
    println("Callign collect again...")
    flow.collect{value -> println(value)}
}
```

simple call returns quickly and soes not wait for anything. The flow starts every time it is collected.

## Flow cancellation basics

flow collection can be cancelled when the flow is suspended in a cancellable suspending function.

```kotlin
fun simple(): Flow<Int> = flow{
    for(i in 1..3){
        delay(100)
        println("Emitting $i")
        emit(i)
    }
}
fun main() = runBlocking<Unit>{
    withTimeoutOrNull(250){
        simple().collect{value -> println(value)}
    }
    println("Done")
}
```

## Flow Builders

There are other builders for easier declaration of flows:

1. flowOf builder that defines a flow emmitting a fixed set of values.
2. .asFlow() extension function.



```kotlin
(1..3).asFlow().collect{value -> println(value) }
```



## Intermediate flow operators

Flows can be transformed with operators, just as you would with collections and sequences.

These operators are cold.

```kotlin
suspend fun performRequest(request: Int): String{
    delay(1000)
    return "response $request"
}
fun main = runBlocking<Unit>{
    (1..3).asFlow()
    .map{request -> performRequest(request)}
    .collect{response -> println(response)}
}

```

### Transform operator

使用transform进行复杂的变换。

```kotlin
(1..3).asFlow()
.transform{ request-> 
          emit("Making request $request")
          emit(performRequest(request))
          }
.collect{response -> println(response)}
```

### Size-limiting operators

中间变换符（intermediate operators）例如take可以取消flow的运行， 同时cancellation 在协程中以异常抛出。

```kotlin
fun numbers(): Flow<Int> = flow{
    try{
        emit(1)
        emit(2)
        println("This line will not execute")
        emit(3)
    }finally{
        println("Finally in numbers")
    }
}
fun main() = runBlocking<Unit>{
    numbers()
    .take(2)
    .collect{value -> println(value)}
}
```

## Terminal flow operator

Terminal operators 是一个suspend函数， 对flow开始collect。

转换到一个集合使用toList和toSet

first获得第一个值，single 让flow只发出一个值。

reduce和fold将flow减少到一个值

```kotlin
val sum = (1..5).asFlow()
.map{it * it}
.reduce{a, b -> a + b}
println(sum)
```

## Flows are sequential

除非使用对多个流操作的特殊操作符， 否则独立的集合的流的是有序的

```kotlin
(1..5).asFlow()
.filter{
    println("Filter $it")
    it % 2 == 0
}
.map{
    println("Map $it")
    "string $it"
}.collect{
    println("Collect $it")
}
```

## Flow Context

流的收集总是在一个协程上下文的

```kotlin
withContext(context){
    simple().collect{value ->
         println(value)
    }
}
```

这种属性也称为流的上下文保存。

```kotlin
fun simple(): Flow<Int> = flow{
    log("Started simple flow")
    for(i in 1..3){
        emit(i)
    }
}
fun main() = runBlocking<Unit>{
    simple().collect{value -> log("Collected $value")}
}
```

### Wrong emission withContext

长时耗时操作应该执行在Dispatchers.Default上，UI更新操作应该执行在Dispatchers.Main上。

```kotlin
fun simple(): Flow<Int> = flow{
    //The WRONG way to change context for CPU-consuming code in flow builder.
    kotlinx.coroutines.withContext(Dispatchers.Default){
        for(i in 1..3){
            Thread.sleep(100) //pretend we are computing it in CPU-consuming way
            emit(i);
        }
    }
}
fun main() = runBlocking<Unit>{
    simple().collect{value -> println(value)}
}

```



![image-20220708172217210](https://s2.loli.net/2022/07/08/mlxbwK7NESZtXrc.png)

### flowOn operator

flowOn用于更改emit的上下文

```kotlin
fun simple(): Flow<Int> = flow{
    for(i in 1..3){
        Thread.sleep(100)
        log("emitting $i")
        emit(i)
    }
}.flowOn(Dispatchers.DEFAULT)

fun main() = runBlocking<Unit>{
    simple().collect{value -> log("Collected $value")}
}
```

## Buffering

