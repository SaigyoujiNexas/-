# jdk 17 的新特性

## 字符块

无视任何特殊字符（支持全部转义字符，新增 \, \s, ）

```java
    String str1 = """
        #include<stdio.h>
        #include<assert.h>
        int main(){
            printf("Hello, world!");
            return 0;
        }""";
```

```java
String.stripIndent();		//缩进处理
String.translateEscapes();	//对转义序列处理
String.formatted(T ...args);	//格式化
```



### 密封类

对继承加以限制

```java
public abstract sealed class Shape{
    
     final class Circle  extends Shape{
        public Circle() {
        }
    }
    final class Rect extends Shape{
    }
}
class tted extends Shape{
    
}
```

```java
public abstract sealed class Shape permits Test.Shape.Circle, Test.Shape.Rect {

     final class Circle  extends Shape{
        public Circle() {
        }
    }
    non-sealed class Rect extends Shape{
    }
}
class ttet extends  Shape{
    
}
```

## recode 类型

类似于kotlin的数据类

```java
record  kksk(double x, double y){

}
```

## switch表达式

便携式表达

```java
String str = switch (i)
                {
                    case 1 -> "Hello";
                    case 2 -> "World";
                    default -> {
                        if(i < 0)
                            yield "Text";
                        else
                            yield "test";
                    }
                };
```

## 模式匹配

```java
public static void  pdd(Object obj)
    {
        if(obj instanceof String s)
            System.out.println(s);
    }
```



```java
    public static void  pdd(Object obj)
    {
        switch (obj)
        {
            case String s -> System.out.println(s);
            default -> System.out.println("I do not know");
        }
    }
```

