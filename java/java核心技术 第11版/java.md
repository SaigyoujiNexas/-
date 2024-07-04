@[TOC](java核心技术 第11版 泛型程序设计)

泛型的引入， java允许设计者详细的描述变量和方法的类型要如何变化

# 定义简单泛型类



```java
public class pair<T>
{
    private T first;
    private T second;
    
    public Pair() {first = null; second = null;}
    public Pair(T first, T second) {this.first = first, this.second = second;}
    
    public T getFirst() {return first;}
    public T getSecond() {return second;}
    
    public void setFirst(T newValue) {first = newValue;}
    public void setSecond(T newValue) {second = newValue;}
}
```

**java库使用E表示集合的元素类型， K和V分别表示键和值的类型， T表示任意类型**

pair1/PairTest1.java

```java
package pair1;

/**
 * @author Cay Horstann
 */

public class PairTest1
{
    public static void main(String[] args)
    {
        String[] words = {"Mary", "had", "a", "little", "lamb"};
        Pair<String> mm = ArrayAlg.minmax(words);
        System.out.println("min = " + mm.getFirst());
        System.out.println("max = " + mm.getSecond());
    }
}

class ArrayAlg
{
    /**
     * Get the minimum and maximum of an array of strings,
     * @param a an array of strings
     * @return a pair with the min and max values, or null if a is null or empty
     */
    public static Pair<String> minmax(String [] a)
    {
        if (a == null || a.length == 0) return null;
        String min = a[0];
        String max = a[0];
        for (int i = 1; i < a.length; i++)
        {
            if(min.compareTo(a[i]) > 0) min = a[i];
            if(max.compareTo(a[i]) < 0) max = a[i];
        }
        return new Pair<>(min, max);
    }
 }
```

# 泛型方法

还可以定义一个带有类型参数的方法

```java
class ArrayAlg
{
    public static <T> T getMiddle(T...a)
    {
        return a[a.length / 2];
    }
}
```

 泛型方法可以在普通类内进行定义， 也可以在泛型类中

```java
String middle = ArrayAlg.<String> getMiddle("John", "Q.", "Public");
```

大多数情况下可以省略类型参数

```javav
String middle = ArrayAlg.getMiddle("John", "Q.", "Public");
```

偶尔编译器也会提示错误， 此时需要自行解读

# 类型变量的限定

```java
class ArrayAlg
{
    public static <T> min (T[] a) almost correct
    {
        if (a == null || a.length == 0) return null;
        T smallest = a[0];
        for (int i = 1; i < a.length; i++)
        {
            if(smallest.compareTo(a[i]) > 0) smallest = a[i];
        }
        return  smallest;
    }
}
```

T所属的类可能没有compareTo方法

解决方法是限制T只能是实现了Comparable接口， 可以通过对T设置限定（bound）来实现

```java
public static <T extends Comparable> T min (T[] a)...
```

对于记法

```java
T extends Comparable & Serializable
```

表示T应该是限定类型（bounding type）的子类型（subtype）， T和限定类型可以是类， 也可以是接口， 其更接近子类型的概念

pair2/ PairTest2.java

```java
package pair2;
import java.time.*;

/**
 * @author Cay Horstmann
 */

public class PairTest2 
{
    public static void main(String[] args)
    {
        LocalDate[] birthdays = 
        {
            LocalDate.of(1906, 12, 9) ,     //G. Hopper
            LocalDate.of(1815, 12, 10),     //A. Lovelace
            LocalDate.of(1903, 12, 3),      //J.von Neumann
            LocalDate.of(1910, 6, 22),      //K. Zuse
        };
        Pair<LocalDate> mm = ArrayAlg.minmax(birthdays);
        System.out.println("min = " + mm.getFirst());
        System.out.println("max = " + mm.getSecond());
    }
    
}

class ArrayAlg
{
    /**
     * Gets the minimum and maximum of an array of objects of type T.
     * @param a an array of objects of type T
     * @return a pair with the min and max values, of null if a is null or empty
     */

     public static <T extends Comparable> Pair<T> minmax(T[] a)
     {
         if (a == null || a.length == 0) return null;
         T min = a[0];
         T max = a[0];
         for (int i = 0; i < a.length; i++)
         {
            if (min.compareTo(a[i]) > 0) min = a[i];
            if (max.compareTo(a[i]) < 0) max = a[i];    
        }
        return new Pair<>(min, max);
     }
}
```



