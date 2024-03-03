@[TOC](类进阶)

# 类成员

| 数据成员    | 函数成员                                                 |
| ----------- | -------------------------------------------------------- |
| 字段， 常量 | 方法， 属性， 构造函数， 析构函数。 运算符， 索引， 事件 |

修饰符： 

* 如果有修饰符， 必须放在核心声明之前
* 如果有多个修饰符，  要有序放置

特性：

* 如果有特性， 必须放在修饰符和核心声明之前
* 如果有多个特性， 要有序放置

# 实例类成员

```csharp
  class Program
    {
        static void Main()
        {
            D d1 = new D();
            D d2 = new D();
            d1.Mem1 = 10;
            d2.Mem1 = 28;
            Console.WriteLine("d1 = {0}, d2 = {1}", d1.Mem1, d2.Mem1);
        }
    }
    class D
    {
        public int Mem1;

    }
```

# 静态字段

静态字段被类的所有实例共享

```csharp
class D{
    int Mem1;
    static int Mem2; 		//静态字段
}
```

# 从类的外部访问静态成员

```csharp
D.Mem2 = 5;
```

## 静态字段示例

```csharp
    class Program
    {
        static void Main()
        {
            D d1 = new D();
            D d2 = new D();
            d1.SetVars(2, 4);
            d1.Display("d1");
            d2.SetVars(15, 17);
            d2.Display("d2");
            d1.Display("d1");
        }
    }
    class D
    {
       int Mem1;
        static int Mem2;
        public void SetVars(int v1, int v2)
        {
            Mem1 = v1;
            Mem2 = v2;
        }
        public void Display(string str)
        {
            Console.WriteLine("{0}: Mem1 = {1}, Mem2 = {2}", str, Mem1, Mem2);
        }
    }
```

## 静态成员的生存期

静态字段再类的任何静态成员被使用之前初始化。



## 静态函数成员

静态函数成员独立于任何类实例， 即使没有类的实例， 仍然可以调用静态方法。

静态函数成员不能访问实例成员， 但可以访问其他静态成员

```csharp
class X
{
    static public int A;
    static public void PrintvalA()
    {
        Console.WriteLine("Value of A: {0}", A);
    }
}
```

```csharp
class Program
{
    static void Main()
    {
        X.A = 10;
        X.PrintValA();
    }
}
```

# 其他静态类成员类型

**数据成员的常量和函数成员的索引不能声明为 static**



## 成员常量

```csharp
class MyClass
{
    const int IntVal = 100;
}
const double PI = 3.1416	//Error: can not declared out of the type declaration
```

用于初始化成员常量的值在编译期必须是可计算的。

```csharp
class MyClass
{
    const int IntVal1 = 100;
    const int IntVal2 = 2 * IntVal1;
}
```

## 常量就像静态量

其对类的每个实例都是可见的

```csharp
    class X
    {
        public const double PI = 3.1416;
    }
    class Program
    {
        static void Main()
        {
            Console.WriteLine("pi = {0}", X.PI);
        }
    }
```

然而， 与真正的静态量不同， 常量没有自己的存储位置， 只是在编译时被编译器替换。类似于define

# 属性

```csharp
MyClass mc = new MyClass();

mc.MyField = 5;
mc.MyProperty = 10; 	// 给属性赋值
WriteLine("{0} {1}", mc.MyField, mc.MyProperty);
```

属性有如下特性：

* 它是命名的类成员
* 它有类型
* 它不为数据存储分配内存
* 它执行代码

## 属性声明和访问器

set和get访问器有预定义的语法：

* set访问器有一个单独的， 隐式的值参， 名称为value， 与属性的类型相同。
* set访问器返回类型为 void
* get访问器没有参数
* get访问器拥有一个和属性类型相同的返回类型

## 属性示例

```csharp
    class C1
    {
        private int TheRealValue;
        public int MyValue
        {
            set
            {
                TheRealValue = value;
            }
            get {
                return TheRealValue;
            }
        }
    }
```

## 使用属性

```csharp
MyValue = 5; 		//隐式调用set方法
z = MyValue;		//表达式： 隐式调用get方法
```

**不能显式调用访问器**

## 属性和关联字段

```csharp
class C1
{
	private int TheRealValue = 10;
    public int MyValue
    {
        set { TheRealValue = value; }
        get  {return TheRealValue;}
    }
}
class Program
{
    static  void Main()
    {
        C1 c = new C1();
        Console.WriteLine("MyValue: {0}", c.MyValue);
        
        c.MyValue = 20;
        Console.WriteLine("MyValue: {0}", c.MyValue);
    }
}
```

## 执行其他计算

```csharp
int TheRealValue = 10;

int MyValue
{
    set
    {
        TheRealValue = value > 100? 100: value;
    }
    get
    {
        return TheRealValue;
    }
}
```

## 只读和只写属性

* 只有get访问器的属性称为只读属性， 反之则为只写属性。

## 计算只读属性示例

```csharp
    class RightTriangel
    {
        public double A = 3;
        public double B = 4;

       public double Hypotenuse     //only read
        {
            get {
                return Math.Sqrt((A * A) + (B * B));
            }
        }
    }
    class Program
    {
        static void Main()
        {
            RightTriangel c = new RightTriangel();
            Console.WriteLine("Hypotenuse: {0}", c.Hypotenuse);
        }
    }
```



## 属性和数据库示例

```csharp
        int MyDatabaseValue
        {
            set {
                SetValueInDatabase(value);
            }
            get {
                return GetValueFromDatabase();
            }
        }
```

## 属性 VS 公共字段

通常属性会更好一些

* 属性是函数型成员， 允许处理输入和输出， 而公共字段不行
* 编译后的变量和编译后的属性语义不同

## 自动实现属性

* 不声明后备字段
* 不能提供访问器的方法体
* 除非通过访问器， 否则不能访问后备字段

```csharp
    class C1
    { 
        public int MyValue
        { set; get; }
    }
    class Program
    {
        static void Main()
        {
            C1 c = new C1();
            Console.WriteLine("MyValue: {0}", c.MyValue);
            c.MyValue = 20;
            Console.WriteLine("MyValue: {0}", c.MyValue);
        }
    }
```

## 静态属性

属性也可以声明为static

```csharp
    class Trivial
    {
        public static int MyValue { get; set;  }
        public void PrintValue()
        {
            Console.WriteLine("Value from inside: {0}", MyValue);
        }
    }
    class Program
    {
        static void Main()
        {
            Console.WriteLine("Init Value: {0}", Trivial.MyValue);
            Trivial.MyValue = 10;
            Console.WriteLine("New Value: {0}", Trivial.MyValue);

            Trivial tr = new Trivial();
            tr.PrintValue();
        }
    }
```









