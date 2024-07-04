# null

kotlin更多地把问题放在编译期， 提高程序健壮性

**除非另有规定， 变量不可为null**

```kotlin
fun main()
{
    var str = "butterfly"
    str = null	//wrong
}
```

除非声明为可空类型

```kot	
fun main()
{
    var str:String? = "butterfly" //set to nullable type
    str = null
}
```

kotlin不允许在可空类型值上调用函数， 除非主动接手安全管理

## 选项一: 安全调用操作符

```kotlin
fun main()
{
    var str:String? = "butterfly"
    str = null
    str?.replaceFirstChar { char -> char.uppercaseChar() }
}
```

? ： 安全调用操作符， 遇到null时直接跳过函数调用

### 使用带let的安全调用

```kot
fun main()
{
    var str:String? = "butterfly"
    str = null
    str = str?.let
    {
    	if(it.isNotBlank())
    	{
   	 		it.capitalize();
    	}
    	else
    	{
    		"butterfly"
    	}
    }
    println(str)
}
```

## 选项二： 使用非空断言符

```kotlin
fun  main()
{
    val str = readLine()!!.capitalize()
    println(str)
}
```

遇到空值后抛出KotlinNullPointerException

## 选项三： if判断

```kotlin
if(str == null)
{
    ....
}
```

可以用安全操作符实现链式调用

```kotlin
str?.capitalize()?.plus(" is great.")
```

### 使用空合并操作符

如果左边求值null， 则返回右边的值， 与let使用有奇效

```kotlin
var strWithSafe = str?: "butterfly"
println(str ?: "jack")
str = str?.let(it.capitalize()) ?: "butterfly"
```



#  异常

```kotlin
fun main()
{
    var number:  Int? = null
    try{    
        number!!.plus(1)
    }catch(e: Exception)
    {
        println(e)
    }
}

fun checkOperation(number: Int?){
    number ?: throw UnskilledException()
}

class UnskilledException(): IllegalArgumentException("操作不当")
```

## 先决条件函数

![image-20211028232009302](https://i.loli.net/2021/10/28/5XjkG28oaNYuKAU.png)

```kotlin
fun checkOperation(number: Int?): Int
{
    checkNotNull(number, {"something is not good."})
}
```

