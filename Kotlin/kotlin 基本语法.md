## kotlin 基本语法

## 只读变量

使用val声明

## 编译时常量

编译时常量只能在函数之外定义

```kotlin
const val MAX = 200
```



## 表达式

### if / else 表达式

不多赘述

### range 表达式

```kotlin
fun main(){
    val age = 4;
    if(age in 0..3)
    println("婴幼儿")；
    else if (age in 3..12)
    println("少儿");
    else
    println("位置")
}
```



### when表达式

```kotlin
val school = "小学"
val level = when(school)
{
    "学前班" -> "幼儿"
    "小学" -> "少儿"
    else -> {println("未知")}
}
```

## string模板

```kotlin
fun main()
{
    val origin = "Jack"
    val dest = "Rose"
    println("$origin love $dest")
    val flag = false
    println("Answer os: ${if(flag) "我可以" else "对不起"}")
}
```

# 函数

## 函数头

![image-20211013225257959](https://i.loli.net/2021/10/13/CdFxg3tZeWTBv9c.png)

```kotlin
fun main()
{
    println(doSomething(5, false))
}
private fun doSomething(age: Int, flag: Boolean) : String{
    return "result";
}
```

## 函数参数

如果不打算传参， 可以提供默认值

```kotlin
fun fix(name: String, age: Int = 2)
{
    println(name + age)
}
```

如果使用命名值参， 就可以不用管顺序

```kotlin
fun main()
{
    fix(age = 10, name = "Jack")
}
fun fix(name: String, age: Int = 2)
{
    println(name + age)
}
```

## Unit函数

没有返回值的函数叫Unit函数。

```kotlin
fun main()
{
    println(fix(age = 10, name = "Jack"))
}
fun fix(name: String, age: Int = 2)
{
    println(name + age)
}
```

## Nothing 类型

TODO函数任务就是抛出异常， 返回的为Nothing类型

```kotlin
fun main(){
    println(fix(age = 10, name = "Ros"))
    TODO("nothing");
    println("after nothing")
}
```

## 反引号中的函数名

* Kotlin可以使用空格和特殊字符对函数命名， 不过需要用反引号括起来（为了让java和kotlin相互转化， 解决冲突）

```java
public class MyJava 
{
    public static void is()
    {
        System.out.println("is invoked");
    }
}
```

```kotlin
fun main()
{
    MyJava.`is`();
}
fun `**special function with weird name~**`()
{
}
```

