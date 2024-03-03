# 优雅的使用Data class

```kotlin
data class Book(
    val id: Long,
    val name:String,
    val author: Person
)
```

data class 不可以被继承

最好是基本类型或其他data class

声明在主构造器的Component不可以自定义Getter 和Setter

## 解构

```kotlin
data class Person(val id: String, val name: String)

val bennyhuo = Person(2, "bennyhuo")
val (id, name) = bennyhuo
println("$id $name")

```

```kotlin
fun returnTwoValues() = "Kotlin" to "JetBrains"
// dataclass
/**
*infix fun <A, B> A.to(that: B): Pair<A, B> = *Pair(this, that)
*/
val (kotlin, Jetbrains) = returnTwoValues()

fun returnThreeValues() = Triple("Kotlin", "JetBrains", "Beijing")

```

数组解构

```kotlin
val(a) = arrayOf(1)
val(a, b) = arrayOf(1, 2)
....
val (a, b, c, d, e, f) = arrayOf(1, 2, 3, 4, 5, 6)
//more than senven can not work, bacause of jetbrains are not implement this methods.
//you can impl it by your self
operator fun<T> Array<out T>.component6():T{
    return get(5)
}
```

## 可变属性

```kotlin
data class(
    val id : String,
    val name: String, 
    var age: Int
)

```

当age改变时， age改变时， hashCode会改变， equals方法使用会出现问题

deepCopy 反射实现

```kotlin
fun<T: Any> T.deepCopy(): T{
    if(!this::class.isData) {return this}
    return this::class.primaryConstructor!!.let{
        primaryConstructor -> 
        primaryConstructor.parameters.map{
            parameter ->
            val value = 
            (this::class as KClass<T>)
            .declaredMemberProperties.first{it.name == parameter.name}.get(this)
            if((parameter.type.classifier as? KClass<*>) ?.isData == true){
                parameter to value?.deepCopy()
            }else{
                parameter to value
            }
        }.toMap().let{
            primaryConstructor::callBy
        }
    }
}
```

## 追加无参构造方法

```groovy
dependencies{
    ...
	classpath "org.jetbrains.kotlin:kotlin-noarg:1.3.0"
}
apply plugin: "kotlin-noage"
noArg{
    invokeInitializers = true
    annotations "....."
}
```





