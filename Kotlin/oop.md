# field

kotlin会自动生成getter和setter， 而在需要自行控制读写时使用field

```kot
class Player {
    var name =  "jack"
        get() = field.replaceFirstChar {
            if (it.isLowerCase()) 
            it.titlecase(Locale.getDefault()) 
            else 
            it.toString() 
            }
    set(value)
    {
        field = value.trim()
    }
}
```

## 计算属性

```kotlin
val rolledValue
    get() = (1..6).shuffled().first()
```

## 防范竞态条件

若一个属性即可空又可变， 引用他之前必须保证非空， 一个办法是使用also

# 主构造函数

使用临时变量为各个属性赋值， 临时变量名通常以下划线开头

```kotlin
class Player (
    _name: String,
    _age:Int,
    _isNormal: Boolean
        ){
    var name = _name
    get() = field.capitalize()
    set(value){field = value.trim()}
    var age = _age
    get() = field.absoluteValue
    set(value) {field = age.absoluteValue}
    var isNormal = _isNormal
}
```

## 主构造函数中定义属性

```kotlin
class Player (
    _name: String,
    var age:Int,
    var isNormal: Boolean
        ){
    var name = _name
}
```

# 次构造函数

```kotlin
class Player (
    _name: String,
    var age:Int,
    var isNormal: Boolean
        ){
    var name = _name
    constructor(name: String): this(name, age = 100, isNormal = false)
    constructor(name: String, age: Int) : this(name, age = 10, isNormal = false){
        this.name = name.toUpperCase()
    }
}
```

## 默认参数

定义构造函数时可以传递默认值

```kotlin
class Player (
    _name: String,
    var age:Int = 20,		//default is 20
    var isNormal: Boolean
        ){
    var name = _name
    constructor(name: String): this(name, age = 100, isNormal = false)
}
fun main()
{
    Player(_name = "Jack", isNormal = false)
}
```

# 初始化块

初始化块会在构造类实例时启动

(静态代码块在类被加载进虚拟机时启动)

```kotlin
class Player (
    _name: String,
    var age:Int,
    var isNormal: Boolean
        )
{
    var name = _name
    constructor(name: String): this(name, age = 100, isNormal = false)
    init {
        require(age > 0) {"age must be positive"}
        require(name.isNotBlank()){"player must have a name."}
    }
}
```

# 初始化顺序

主构造函数声明的属性-> 类属性赋值->init块调用-> 次构造函数调用

![image-20211031170654777](https://i.loli.net/2021/10/31/KVEUcOey7uYIbfn.png)

## 延迟初始化

lateinit关键字实现

```kotlin
class Player4 {
    lateinit var equipment: String
    fun ready()
    {
        equipment = "sharp knife"
    }
    fun battle()
    {
       // println(equipment)	if battle first without ready, it will puts a Exception
        if(::equipment.isInitialized) println(equipment)
    }
}
fun main()
{
    val p = Player4()
    p.ready()
    p.battle()
}
```

## 惰性初始化

先写好初始化， 当调用该属性时才会初始化

（就是单例模式的懒汉式， 饿汉式）

```kotlin
class Player5(_name: String){

	var name = _name

val config by lazy{loadConfig()}

	private fun loadConfig(): String{

	println("loading...")

	return "xxx"

}

}
fun main(){
    val p = Player5("Jack")
    Thread.sleep(3000)
    println(p.config)
}
```



# 继承

Kotlin中的类默认都是封闭的， 若需要开放继承， 使用open关键字

函数重写也一样

```kotlin
open class Product(val name: String){
    fun description() = "Product: $name"
    open fun load() = "Nothing..."
}
class LuxuryProduct: Product("Luxury")
{
    override fun load() = "LuxuryProduct loading.."
	fun special() = "LuxuryProduct special"
}

fun main(){
    val p: Product = LuxuryProduct()
    println(p.load())
    println(p is Product)
    println(p is LuxuryProduct)
    println(p is File)
    if(p is LuxuryProduct)
    {
        println((p as LuxuryProduct).special())
    }
}
```

## 智能类型转换

```kotlin
println((p as LuxuryProduct).special())
println(p.special())
```

# Kotlin 层次

Kotlin中Any是每一个类的超类

