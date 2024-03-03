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

# 泛型代码和虚拟机

## 类型擦除

无论何时定义一个泛型类型， 都会自动提供一个相应的原始类型（raw type）。 这个原始类型的名字就是去掉类型参数后的泛型类型名。 类型变量会被擦除（erased）， 并替换为其限定类型， 对于无限定类型的变量则替换为Object。

假定有如下声明：

```java
public class Interval<T extends Comparable & Serializable> implements Serializable
{
    private T lower;
    private T upper;
    ...
    public Interval(T first, T second)
    {
        if(first.compareTo(second) <= 0) {lower = first; upper = second;}
        else
        {
            lower = second;
            upper =first;
        }
    }
}
```

原始类型如下：

```java
public class Interval implements Serializable
{
    private Comparable lower;
    private Comparable upper;
    ...
    public Interval(Comparable first, Comparable second) {...}
}
```



## 转换泛型表达式

```java
Pair<Employee> buddies = ...;
Employee buddy = duddies.geFirst();
```

编译器将getFirst方法拆分为两条虚拟机指令

1. 对原始方法Pair.getFirst方法调用
2. 将返回的Object类型强制转换为Employee类型

## 转换泛型方法

对于方法

```java
public static <T extends Comparable>T min(T[] a)
```

擦除类型后

```java
public static Comparable min (Comparable[] a)
```

对于

```java
class DateInterval extends Pair<LocalDate>
{
    public void setSecond(LocalDate second)
    {
        if(second.compareTo(getFirst()) >= 0)
            super.setSecond(second);
    }
    ...
}
```

类型擦除后

```java
class DateInterval extends Pair
{
    public void setSecond(LocalDate second){...}
}
```

还有一个从Pair继承的setSecond方法

```java
public void setSecond(Object second)
```

对于下列语句

```java
var interval = new DateInterval(...);
Pair<LocalDate> pair = interval;
pair.setSecond(aDate);
```

setSecond类型擦除和多态发生了冲突， 为解决该问题， 编译器在DateInterval中生成了一个桥方法（bridge method）:

```java
public void setSecond(Object second) {setSecond((LocalDate) second);}
```

 对于java泛型的转换

1. 虚拟机中没有泛型， 只有普通的类和方法
2. 所有的类型参数都会替换为它们的限定类型
3. 会合成桥方法来保持多态
4. 为保持类型安全性， 必要时插入强制类型转换

## 调用历史遗留代码

java泛型的主要目的是允许泛型代码和恶遗留代码之间能够互操作

```java
Dictionary<Integer, Component> labelTable = new HashTable<>();
labelTable.put(0, new JLabel(new ImageIcon("nine.gif")));
labelTeble.put(20,new JLabel(new ImageIcon("ten.gif")));
```

将Dictionary< Integer, Component >对象传递给setLabelTable时， 编译器会发出警告

因为编译器无法确定setLabelTable到底用Dictionary对象做什么（没有参数类型的Dictionary泛型类， 和从未更新的java5之前的Slider存在兼容性问题）

对于

```java
Dictionary<Integer, Components> labelTable = silder.getLabelTable();
```

这样做会看到一个警告

确保标签表确实包含Integer和Component对象，恶意的程序员可能在滑块中安装一个不同的Dictionary， 不过这种情况并不会比有泛型之前的情况更糟， 最差的情况也就是程序抛出一个异常

考虑该警告后， 可以使用注解（annotation）使之消失

```java
@SuppressWarnings("unchecked")
Dictionary<Integer, Components> labelTable = slider.getLableTable(); //no warning
```



# 限制与局限性

1. 不能用基本类型实例化类型参数

2. 运行时类型查询只适用于原始类型

3. 不能创建参数化类型的数组， 如果需要收集参数化类型对象， 简单使用ArrayList< Pair< String > >即可

4. Varargs警告

   ```java
   @SafeVarargs
   public static <T> void addAll(Collection<T> coll, T... ts)
   ```

   对于任何只需要读取参数数组元素的方法都可以使用这个注解

5. 不能实例化类型变量

   ```java
   public Pair() {first = new T(); second = new T();} //ERROR
   ```

   该构造器非法。

   ```java
   public static <T> Pair<T> makePair(Supplier<T> constr)
   {
       return new Pair<>(constr.get(), constr.get());
   }
   ```

   ```java
   Pair<String> p = Pair<T>makePair(string::new);
   ```

   传统方法为通过反射调用Constructor.newInstance方法构造泛型对象。

   

   ```java
   public static <T> Pair<T> makePair(Class<T> cl)
   {
   	try
   	{
       	return new Pair<>(cl.getConstructor().newInstance()), cl.getConstructor().newInstance());
   	}
   	catch (Exception e){return null; }
   }
   ```

6. 不能构造泛型数组

   ```java
   public static <T extends Comparable> T[] minmax(T...a)
   {
       T[] mm = new T[2];		//ERROR 
   }
   ```

   类型擦除会使该方法总是构造Comparable数组

   ```java
   public static <T extends Comparable> T[] minmax(T...a)
   {
       var result  =  new Comparable[2]; 		//array of erased type
       ...
       result (T[]) result;		//compiles with warning
   }
   ```

   将会出现ClassCastException

   最好让用户提供一个数组构造器表达式

   ```java
   String [] names = ArrayAlg.minmax(String[]::new, "Tom", "Dick", "Harry");
   ```

   minmax方法使用该参数生成一个有正确类型数组：

   ```java
   public static <T extends Comparable> T[] minmax (IntFunction<T[]> constr, T...a)
   {
       T[] result = constr.apply(2);
       ...
   }
   ```

   老式方法是利用反射：

   ```java
   public static <T extends Comparable> T[] minmax (T...a)
   {
       var result = (T[]) Array.newInstance(a.getClass().getComponentType(), 2); 
       ...
   }
   ```

   ArrayList类的toArray方法则需要生成一个T[]数组， 但没有元素类型

   有下面两种形式：

   ```java
   Object[] toArray()
   T[] toArray(T[] result)
   ```

   第二个方法接受一个数组参数， 若数组足够大， 就使用这个数组， 否则， 用result的元素类型构造一个足够大的新数组

7. 泛型类的静态上下文中类型变量无效

   不能在静态字段或方法中引用类型变量

   ```java
   public class Singleton<T>
   {
       private static T singleInstance;		//ERROR
       private static T getSingleInstance()	//ERROR
       {
           if(singleInstance == null) construct new instance of T
               return singleInstance;
       }
   }
   ```

8. 不能抛出或捕捉泛型类的实例

   泛型类扩展Throwable都不允许

   ```java
   public class Problem<T> extends Exception{.....} 		//ERROR
   ```

   catch子句不能使用类型变量

   ```java
   public static <T extends Throwable> void doWork(Class<T> t)
   {
       try
       {
           do work
       }
       catch(T e)	//ERROR can not catch type variable
       {
           Logger.globle.info(...);
       }
   }
   ```

   在异常规范中使用类型变量可行

   ```java
   public static <T extends Throwable> void d
   {
       try
       {
           do work
       }
       catch (Throwable realCause)
       {
           t.initCause(realCause);
           throw t;
       }
   }
   ```

9. 可以取消对检查型异常的检查

   ```java
   @SuppressWarnings("unchecked")
   static <T extends Throwable> void throwAs(Throwable t) throws T
   {
       return (T) t;
   }
   ```

   ```java
   try
   {
       do work
   }
   catch (Throwable t)
   {
       Task.<RuntimeException>throwAs(t);
   }
   ```

   利用此可以将一个检查型异常转换为非检查型异常

10. 注意擦除后的冲突

    泛型类型被擦除后， 不允许创建引发冲突的条件

    泛型规范说明引用了另一条原则， 倘若两个接口类型是同一接口的不同参数化， 一个类或类型变量就不能同时作为这两个接口类型的子类

    ```java
    class Employee implements Comparable<Employee> {...}
    class Manager extends Employee implements Comparable<Manager> {...}			//ERROR
    ```

    其原因与合成的桥方法产生冲突有关， 实现了Comparable< X > 的类会获得一个桥方法：

    ```java
    public int compareTo(Object other) {return compareTo((X) other);}
    ```

    不能对不同的类型X有两个这样的方法

    # 泛型类型的继承规则

    Pair< Manager >与Pair < Employee >两者没有任何关系
    
    ```java
    Manager [] topHonchos = ...;
    Pair<Employee> result = ArrayAlg.minmax(topHonchos); 		//ERROR
    ```
    
    转换成原始类型依旧会出现错误
    
    ```java
    var managerBuddies = new Pair<Manager> (ceo, cfo);
    Pair rawBuddies = managerBuddies;
    rawBuddies.setFirst(new File("..."));	//only a compile-time warning
    ```
    
    泛型类可以拓展或实现其他泛型类
    
    # 通配符类型
    
    ## 通配符概念
    
    ```java
    Pair<? extends Employee>
    ```
    
    
    
    表示任何Pair类型的类型参数是Employee的子类
    
    ```java
    public static void printBuddies(Pair< Employee > p)
    {
    	Employee first = p.getFirst();
        Employee second = p.getSecond();
        System.out.println(irst.getName() +  " and " + second.getName() + " are buddies.");
    }
    ```
    
    这样不能将Pair< Manager > 传递给该方法
    
    ```java
    public static void printBuddies (Pair<? extends Employee> p)
    ```
    
    使用通配符不会通过Pair<? extends Employee> 的引用破坏Pair< Manager > 
    
    ```java
    var managerBuddies = new Pair<Manager> (ceo, cfo);
    Pair<? extends Employee> wildcardBuddies = managerBuddies;
    wildcardBuddies.setFirst(new File("..."));	//compile-time warning
    ```
    
    只能使用返回值，不能提供参数

## 通配符的超类型限定

```java
? super Manager
```

带有超类型限定的通配符允许写入一个泛型对象， 带有子类型限定的通配符允许读取一个泛型对象。

超类型限定的另一个用法是

对于接口Comparable

```java
public interface Comparable<T>
{
    public int compareTo(T other);
}
```

处理LocalDate对象数组时， 因为LocalDate实现的是Comparable< ChronoLocalDate >, 不是Comparable < LocalDate >,

在这种情况下， 可以用超类型解决。

```java
public static <T extends Comparable<? super T>> T min (T[] a)...
```

## 无限定通配符

```java
? getFirst()
void setFirst(?)
```

返回值只能赋给Object， setFirst方法无法调用，

它对于很多简单操作非常有用

```java
public static boolean hasNulls(Pair<?> p)
{
    return p.getFirst() == null || p.getSecond() == null;
}
```

通过将hasNull转换为泛型方法， 可以避免使用通配符类型

```java
public static <T> boolean hasNulls (Pair<T> p)
```

## 通配符捕获

```java
public static void swap(Pair<?> p)
```

下面代码非法

```java
? t = p.getFirst();
p.setFirst(p.getSecond());
p.setSecond(t);
```

可以写一个辅助方法

```java
public static <T>  void swapHelper(Pair<T> p)
{
        T t = p.getFirst();
        p.setFirst(p.getSecond());
        p.setSecond(t);   
}
```

```java
public static void swap(Pair<?> p) {swapHelper(p);}
```

swapHelper的方法的参数T会**捕获修饰符**

```java
package pair3;

/**
 * @author Cay Horstmann
 */

public class PairTest3 
{
    public static void main(String[] args) {
        var ceo = new Manager("Gus Greedy", 800000, 2003, 12, 15);
        var cfo = new Manager("Sid Sneaky", 600000, 2003, 12, 15);
        var buddies = new Pair<Manager>(ceo, cfo);
        printBuddies(buddies);

        ceo.setBonus(1000000);
        cfo.setBonus(500000);
        Manager[] managers = {ceo, cfo};

        var result = new Pair<Employee>();
        minmaxBonus(managers, result);
        System.out.println("First: " + result.getFirst().getName() + ", second: " + result.getSecond().getName());
        maxminBonus(managers, result);
        System.out.println("First: " + result.getFirst().getName() + ", second: " + result.getSecond().getName());
    }
    public static void printBuddies(Pair<? extends Employee> p)
    {
        Employee first = p.getFirst();
        Employee second = p.getSecond();
        System.out.println(first.getName() + " and " + second.getName() + " are buddies.");
    }

    public static void minmaxBonus(Manager[] a, Pair<? super Manager> result)
    {
        if(a.length == 0) return;
        Manager min = a[0];
        Manager max = a[0];
        for (int i = 1; i < a.length; i++) 
        {
            if (min.getBonus() > a[i].getBonus())
                min = a[i];
            if(max.getBonus() < a[i].getBonus())
                max = a[i];
        }
        result.setFirst(min);
        result.setSecond(max);
    }
    public static void maxminBonus(Manager[] a, Pair<? super Manager> result)
    {
        minmaxBonus(a, result);
        PairAlg.swapHelper(result);   
    }
    //can not write public static <T super manager>...

}

class PairAlg
{
    public static boolean hasNulls(Pair<?> p) 
    {
        return p.getFirst() == null || p.getSecond() == null;   
    }
    public static void swap(Pair<?> p)
    {
        swapHelper(p);   
    }
    public static <T>  void swapHelper(Pair<T> p)
    {
        T t = p.getFirst();
        p.setFirst(p.getSecond());
        p.setSecond(t);   
    }
}
```

# 反射和泛型

## 泛型Class类

Class类是泛型的

### API

java.lang.Class< T >

* ```
  T
  cast(Object obj)
  ```

  Casts an object to the class or interface represented by this `Class` object.

* ```
  public T newInstance()
  ```

  **Deprecated.**

  This method propagates any exception thrown by the nullary constructor, including a checked exception.

* ```
  T[]
  getEnumConstants()
  ```

  Returns the elements of this enum class or null if this Class object does not represent an enum class.

* ```
  Class<? super T>
  getSuperclass()
  ```

  Returns the `Class` representing the direct superclass of the entity (class, interface, primitive type or void) represented by this `Class`.

* ```
  Constructor<T>
  getConstructor(Class<?>... parameterTypes)
  ```

  Returns a `Constructor` object that reflects the specified public constructor of the class represented by this `Class` object.

* ```java
  Constructor<?>[] 
  getConstructors()
  ```

  Returns an array containing `Constructor` objects reflecting all the public constructors of the class represented by this `Class` object.

* ```
  Constructor<T> 
  getDeclaredConstructor(Class<?>... parameterTypes)
  ```

  Returns a `Constructor` object that reflects the specified constructor of the class or interface represented by this `Class` object.

* ```java
  Constructor<?>[] getDeclaredConstructors()
  ```

  Returns an array of `Constructor` objects reflecting all the constructors declared by the class represented by this `Class` object.





java.lang.reflect.Constructor< T >

* ```
  T
  newInstance(Object... initargs)
  ```

  Uses the constructor represented by this `Constructor` object to create and initialize a new instance of the constructor's declaring class, with the specified initialization parameters.

## 使用Class< T > 参数进行类型匹配

匹配泛型方法中的Class< T >的参数的类型变量会很好用

```java
public static <T> Pair<T>  makePair(Class<T> c)
throws InstantiationException, IllegalAccessError
{
    return new Pair<>(c.getDeclaredConstructor().newInstance(), c.getDeclaredConstructor().newInstance());
}
```



## 虚拟机中的泛型类型信息

为了表述泛型类型声明, 可以使用java.lang.reflect包中的接口Type, 包含以下子类型:

* Class类, 描述具体类型
* TypeVariable接口, 描述类型变量(T extends Comparable<? super T>)
* WildcardType接口, 描述通配符(? super T)
* ParameterizedType接口, 描述泛型类或接口类型(Comparable <? super T>)
* GenericArrayType接口, 描述泛型数组( T[] )



```java
package genericReflection;

import java.util.*;

import java.lang.reflect.*;
/**
 * @author Cay Horstmann
 */
public class GenericReflectionTest 
{
    public static void main(String[] args) {
        //read class name from command ling args or user input
        String name;
        if(args.length > 0) name = args[0];
        else
        {
            try (var in = new Scanner(System.in))
            {
                System.out.println("Enter class name (e.g., java.util.Collections): ");
                name = in.next();
            }
        }

        try
        {
            //print generic info for class and public methods
            Class<?> cl = Class.forName(name);
            printClass(cl);
            for(Method m : cl.getDeclaredMethods())
                printMethod(m);
        }
        catch(ClassNotFoundException e)
        {
            e.printStackTrace();
        }
    }
    public static void printClass(Class<?> cl)
    {
        System.out.print(cl);
        printTypes(cl.getTypeParameters(), "<", ", " , ">", true);
        Type sc = cl.getGenericSuperclass();
        if(sc != null)
        {
            System.out.print(" extends ");
            printType(sc, false);
        }
        printTypes(cl.getGenericInterfaces(), " implements ", ", ", "", false);
        System.out.println();
    }
    public static void printTypes(Type[] types, String pre, String sep, String suf, boolean isDefinition)
    {
        if(pre.equals(" extend ") && Arrays.equals(types, new Type[] {Object.class}))
            return;
        if(types.length > 0)    System.out.print(pre);
        for(int i = 0; i < types.length; i++)
        {
            if(i > 0) System.out.print(sep);
            printType(types[i], isDefinition);
        }
        if(types.length > 0) System.out.print(suf);
    }

    public static void printMethod(Method m) 
    {
        String name = m.getName();
        System.out.print(Modifier.toString(m.getModifiers()));
        System.out.print(" ");
        printTypes(m.getTypeParameters(), "<", ", ", "> ", true);
        printType(m.getGenericReturnType(), false);
        System.out.print(" ");
        System.out.print(name);
        System.out.print("(");
        printTypes(m.getGenericParameterTypes(), "", ", ", "", false);
        System.out.println(")");

        
    }
    public static void printType(Type type, boolean isDefinition)
    {
        if(type instanceof Class)
        {
            var t = (Class<?>) type;
            System.out.print(t.getName());
        }
        else if(type instanceof TypeVariable)
        {
            var t = (TypeVariable<?>) type;
            System.out.println(t.getName());
            if(isDefinition)
                printTypes(t.getBounds(), " extends ", " & ", "", false);
        }
        else if(type instanceof WildcardType)
        {
            var t = (WildcardType) type;
            System.out.print("?");
            printTypes(t.getUpperBounds(), " extends ", " & ", "", false);
            printTypes(t.getLowerBounds(), " super", " & ", "", false);
        }
        else if(type instanceof ParameterizedType)
        {
            var t = (ParameterizedType) type;
            Type owner = t.getOwnerType();
            if(owner != null)
            {
                printType(owner, false);
                System.out.print(".");
            }
            printType(t.getRawType(), false);
            printTypes(t.getActualTypeArguments(), "<", ", ", ">", false);
        }
        else if(type instanceof GenericArrayType)
        {
            var t =(GenericArrayType) type;
            System.out.print("");
            printType(t.getGenericComponentType(), isDefinition);
            System.out.print("[]");
            
        }
        
    }
    
}
```



## 类型字面量

有时希望由值的类型决定程序的行为， 可能希望用户指定一种方法来保存某个特定类的对象， 通常实现的方法是将Class对象与一个动作关联

对于泛型类， 可以捕捉泛型接口的实例， 然后构造一个匿名子类

```java
class TypeLiteral
{
    public TypeLiteral()
    {
        Type parentType = getClass().getGenericSuperClass();
        if(parentType instanceof ParameterizedType)
        {
            type = ((ParameterizedType) parentType).getActualTypeArguments()[0];
        }
        else
            throw new UnsupportedOperationException(
        		"Construct as new TypeLiteral<...>(){}");
    }
    ...
}
```

虽然对象的泛型类型已经被擦除， 但字段和方法参数的泛型类型还留存在虚拟机中。

```java
package genericReflection;

import java.lang.reflect.*;
import java.util.*;
import java.util.function.*;



/**
 * A type literal describes a type that can be generic, such as ArrayList<String>.
 */


class TypeLiteral<T>
{
    private Type type;

    /**
     * This constructor must be invoked from an anonymous subclass.
     * as new TypeLiterral<...>(){};
     */
    public TypeLiteral()
    {
        Type parentType = getClass().getGenericSuperclass();
        if(parentType instanceof ParameterizedType)
        {
            type = ((ParameterizedType) parentType).getActualTypeArguments()[0];
        }
        else
        {
            throw new UnsupportedOperationException("Construct as new TypeLiteral<...>(){}");
        }
    }
    private  TypeLiteral(Type type) 
    {
        this.type = type;   
    }
    /**
     * Yields static literal that describes the given type.
     */
    public static TypeLiteral<?> of(Type type)
    {
        return new TypeLiteral<Object>(type);
    }

    public String toString() 
    {
        if(type instanceof Class) return ((Class<?>) type).getName();
        else return type.toString();
    }
    public boolean equals(Object otherObject) 
    {
        return otherObject instanceof TypeLiteral && type.equals(((TypeLiteral<?>) otherObject).type);
    }
    public int hashCode()
    {
        return type.hashCode();
    }
}

/**
 * Formats objects, using rules that associate types with formatting functions.
 */
class Formatter
{
    private Map<TypeLiteral<?>, Function<?, String>> rules = new HashMap<>();

    /**
     * Add a formatting rule to this formatter.
     * @param type the type to which this rule applies.
     * @param formatterForType the function that formats objects of this type
     */

     public <T> void forType(TypeLiteral<T> type, Function<T, String> formatterForType)
     {
         rules.put(type, formatterForType);
     }

     /**
      * Formats all fields of an object using the rules of this formatter.
      @param obj an object
      @return a string with all field names and formatted values
      */

      public String formatFields (Object obj)
      throws IllegalAccessException, IllegalArgumentException
      {
        var result = new StringBuilder();
        for (Field  f : obj.getClass().getDeclaredFields()) 
        {
            result.append(f.getName());
            result.append("=");
            f.setAccessible(true);
            Function<?, String> formatterForType = rules.get(TypeLiteral.of(f.getGenericType()));
            if(formatterForType != null)
            {
                //formatterForType has parameter type ?. Nothing can be passed to its apply
                //method. Cast makes the parameter type to Object so we can invoke it.
                @SuppressWarnings("unchecked")
                Function<Object, String> objectFormatter = (Function<Object, String>)formatterForType;
                result.append(objectFormatter.apply(f.get(obj)));
            }
            else
                 
            result.append("\n");
        }
        return result.toString();
      }
}

public class TypeLiterals
{
    public static class Sample
    {
        ArrayList<Integer> nums;
        ArrayList<Character> chars;
        ArrayList<String> strings;
        public Sample()
        {
            nums = new ArrayList<>();
            nums.add(42);
            nums.add(1729);
            chars = new ArrayList<>();
            chars.add('H');
            chars.add('i');
            strings = new ArrayList<>();
            strings.add("Hello");
            strings.add("World");
        }
    }

    private static <T> String join(String separator, ArrayList<T> elements)
    {
        var result = new StringBuilder();
        for(T e: elements)
        {
            if(result.length() > 0)
                result.append(separator);
            result.append(e.toString());
        }
        return result.toString();
    }
    public static void main(String[] args) 
    throws Exception
    {
        var formatter = new Formatter();
        formatter.forType(new TypeLiteral<ArrayList<Integer>>(){}, lst -> join("", lst));
        formatter.forType(new TypeLiteral<ArrayList<Character>>(){}, lst -> "\"" + join("", lst) + "\"");
        System.out.println(formatter.formatFields(new Sample()));
    }   
}
```

### API

java.lang.Class<T>

* ```
  TypeVariable<Class<T>>[]
  getTypeParameters()
  ```

  Returns an array of `TypeVariable` objects that represent the type variables declared by the generic declaration represented by this `GenericDeclaration` object, in declaration order.

* ```
  Type
  getGenericSuperclass()
  ```

  Returns the `Type` representing the direct superclass of the entity (class, interface, primitive type or void) represented by this `Class` object.

* ```
  Type[]
  getGenericInterfaces()
  ```

  Returns the `Type`s representing the interfaces directly implemented by the class or interface represented by this `Class` object.



java.lang.reflect.Method

* ```
  TypeVariable<Method>[]
  getTypeParameters()
  ```

  Returns an array of `TypeVariable` objects that represent the type variables declared by the generic declaration represented by this `GenericDeclaration` object, in declaration order.

* ```
  Type
  getGenericReturnType()
  ```

  Returns a `Type` object that represents the formal return type of the method represented by this `Method` object.

* ```
  Type[]
  getGenericParameterTypes()
  ```

  Returns an array of `Type` objects that represent the formal parameter types, in declaration order, of the executable represented by this object.



java.lang.TypeVariable

* ```
  String
  getName()
  ```

  Returns the name of this type variable, as it occurs in the source code.

* ```
  Type[]
  getBounds()
  ```

  Returns an array of `Type` objects representing the upper bound(s) of this type variable.



java.lang.reflect.WildcardType

* ```
  Type[]
  getLowerBounds()
  ```

  Returns an array of `Type` objects representing the lower bound(s) of this type variable.

* ```java
  Type[]
  getUpperBounds()
  ```

  Returns an array of `Type` objects representing the upper bound(s) of this type variable.



java.lang.reflect.ParameterizedType

* ```
  Type[]
  getActualTypeArguments()
  ```

  Returns an array of `Type` objects representing the actual type arguments to this type.

* ```
  Type
  getOwnerType()
  ```

  Returns a `Type` object representing the type that this type is a member of.

* ```
  Type
  getRawType()
  ```

  Returns the `Type` object representing the class or interface that declared this type.





java.lang.reflect.GenericArrayType

* ```
  Type
  getGenericComponentType()
  ```

  Returns a `Type` object representing the component type of this array.

