# SpringBoot项目文件结构

创建SpringBoot项目之后会自动生成一个主类，主类中的main方法中调用了`SpringApplication`类的静态方法来启动整个SpringBoot项目，主类的上方有一个`@SpringBootApplication`的注解

```kotlin
@SpringBootApplication
class SpringTestApplication

fun main(args: Array<String>) {
    runApplication<SpringTestApplication>(*args)
}
```

  