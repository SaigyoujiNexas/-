java使用了一种称为**异常处理（exception handing）** 的错误捕获机制， 断言可以有选择的启动检查

# 处理错误

假设java程序运行期间出错，若是某个方法不同通过正常途径完成任务， 方法并不会返回任何值， 而是**抛出（throw）**一个封装错误信息的对象，随后方法退出运行， 异常处理机制开始搜索能处理该情况的**异常处理器（exception handler）**

## 异常分类

异常对象都派生于Throwable类的一个类实例

![image-20210530203546182](D:\dev\Typora\image-20210530203546182.png)

Error类层次结构描述java运行时系统内部错误和资源耗尽错误， 通常很少见， 出错了也几乎无能为力。

由编程错误导致的异常属于RuntimeException.

通常包括：

1. 错误强制类型转换
2. 数组访问越界
3. 访问null指针

不派生于RuntimeException的异常包括

1. 试图超越文件结尾读取数据
2. 试图打开不存在的文件
3. 试图根据给定字符串查找class对象， 而这个字符串表示的类并不存在

派生于Error类或RuntimeException类的所有异常称为**非检查型（unchecked）异常**其他的都是**检查型（checked）异常**

## 声明检查型异常

修改方法首部， 反映这个方法可能抛出的检查型异常

```java
public FileInputStream(String name) throws FileNotFoundException
```

如上， 当程序出错时， 构造器将不会初始化一个新的FileInputStream对象， 而是抛出一个FileNotFoundException类对象， 抛出后程序搜索对应的异常处理器。

无需声明自己编写的方法的所有异常， 在遇到下面四种情况会抛出异常

1. 调用了一个抛出检查型异常的方法， 例如FileInputStream构造器
2. 检测到一错误，并利用throw语句抛出一个检查型异常
3. 程序出错， 抛出一个非检查型异常
4. java虚拟机或运行时库出现内部错误



有些方法应该通过方法首部的**异常规范（exception specification）**声明该方法可能抛出异常

```java
class MyAnimation
{
    ...
    public Image loadImage(String s) throws FileNotFoundException, EOFException
    {
        ...
    }
}
```



子类方法声明的检查型异常不能比超类方法中的更通用， 若超类方法没有抛出任何检查型异常， 子类也同样不能抛出。

抛出的异常有可能是某个特定类的实例， 也有可能属于这个类的一个子类。

## 抛出异常

若readDate读取一个1024字长的文件， 但是只读了733个字节， 此时若要抛出异常：

```java
String readDate(Scanner in) throws EOFException
{
    ...
        while(...)
        {
            if(!in.hasNext()) //EOF encountered
            {
                if(n > len)
                    throws new EOFException();
            }
            ...
        }
    	return s;
}
```

EOFException类有一个包含一个字符串参数的构造器， 可以更细致的描述异常

```java
String gripe  = "Content-length:" + len + ", Received: " + n; 
```

当有一个异常类满足需求时， 抛出异常非常简单

1. 找到一个合适的异常类
2. 创建这个类的一个对象
3. 将对象抛出

一旦方法抛出异常， 该方法不会返回到调用者

## 创建异常类

定义一个派生于Exception的类， 或派生于Exception的某个子类 

通常这个自定义的类包含一个默认的构造器和一个包含详细信息的类, (超类Throwable的toString方法返回一个字符串， 其中包含详细信息)

```java
class FileFormatException extends IOException
{
    public FileFormatException(){}
    public FileFormatException(String gripe)
    {
        super(gripe);
    }
}
```

随后就可以抛出自己的异常类型

```java
String readData(BufferedReader in) throws FileFormatException
{
    ...
        while(...){
            if(ch == -1)
            {
               	if(n < len)
                    throws new FileFormatException();
            }
            ...
        }
    return s;
}
```

### API



java.lang.Throwable

* Throwable() 

  Constructs a new throwable with `null` as its detail message.

* Throwable(String message)

  Constructs a new throwable with the specified detail message.

* Throwable(String message, Throwable cause)

  Constructs a new throwable with the specified detail message and cause.

* protected Throwable (String message, Throwable cause, boolean enableSuppression, boolean writableStackTrace)

  Constructs a new throwable with the specified detail message, cause, [suppression](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/lang/Throwable.html#addSuppressed(java.lang.Throwable)) enabled or disabled, and writable stack trace enabled or disabled.

* Throwable(Throwable cause)

  Constructs a new throwable with the specified cause and a detail message of `(cause==null ? null : cause.toString())` (which typically contains the class and detail message of `cause`).

* String getMessage()

  Returns the detail message string of this throwable.

# 捕获异常

有些代码必须捕获异常

## 捕获异常

捕获异常需要设置try/catch语句块

```java
public void read(String filename)
{
    try
    {
        var in = new FileInputStream(filename);
        int b;
        while((b = in.read()) != -1)			//-1标识文件读到末尾
        {
            process input
        }
        
    }
    catch (IOException exception)
    {
        exception.printStackTrace();
    }
}
```

read方法可能抛出一个IOException异常， 随后进入catch语句， 生成一个堆栈轨迹

## 捕获多个异常

```java
try
{
    code that might throw exceptions
}
catch (FileNotFoundException e)
{
    emergency action for missing files
}
catch (UnknownHostException e)
{
    emergency action for unknown hosts
}
catch (IOException)
{
    emergency action for all other I/O problems
}
```

e.getMessage()获取异常的更多信息

若有详细信息， 可以使用

e.getClass().getName()

得到异常对象的实际类型

java7中同一个catch语句可以捕获多个异常类型

```java
try
{
    code that might throw exception
}
catch (FileNotFoundException | UnknownHostException e)
{
    emergency action for missing files and unknown hosts
}
catch (IOException e)
{
    emergency action for all other I/O problems
}
```

## 再次抛出异常与异常链

通常希望改变异常的类型时会使用该技巧

```java
try
{
    access the database
}
catch (SQLException original)
{
    var e = new ServletException("database error");
    e.initCause(original);
    throw e;
}
```

捕获该异常时， 可以使用如下语句获取原始异常

```java
Throwable original = caughtException.getCause();
```

## finally子句

finally中的语句始终会被执行

```java
var in = new FileinputStream(...);
try
{
    //1
    code that might throw exceptions
    //2
}
catch(IOException e)
{
    //3
    show error message
    //4
}
finally
{
    //5;
    in.close();
}
// 6
```

1. 若代码没有抛出异常。 程序执行顺序为1256

2. 若代码抛出一个异常， 并在catch捕获

   若catch子句没有抛出异常， 执行顺序为1， 3， 4， 5， 6

   若抛出一个异常， 该异常将被抛回到这个方法的调用者， 执行顺序为1， 3， 5

3. 若代码抛出了一个异常， 而catch未捕获， 将执行try中所有语句， 直到抛出异常，随后执行finally， 执行顺序为1， 5



try语句， 可以只有finally子句， 没有catch子句                                                                                                                                                                                                                                          

```java
InputStream in = ...;
try
{
    try
    {
        code that might throw exception
    }
    finally
    {
        in.close();
    }
}
catch(IOException e)
{
    show error message
}
```

内层确保关闭流， 外层确保报告出现的错误

## try-with-Resources语句

```java
try (Resource res = ...)
{
    work with res
}
```

该语句在try块结束时关闭资源

可以指定多个资源

```java
try (var ini = new Scanner(new FileInputStream("/usr/share/dict/words"), StandardCharsets.UTF-8);
    var out = new PrintWriter("out.txt", StandardCharsets.UTF-8))
{
    while(in.hasNext())
        out.println(in.next().toUpperCase());
}
```

java9中， 可以在try首部提供事实最终变量

```java
public static void printAll(String[] lines, PrintWrite out)
{
    try(out){	//effectively final variable
        for (String line: lines)
            out.println(line);
    }//out.close() called here
}
```

当try块抛出一个异常， close方法同样抛出一个异常时， try-with-resources 语句抛出原来异常， 抑制close方法抛出的异常， 并由addSuppressed方法增加进原来的异常， 此时可以调用getSuppressed方法， 其生成抛出并被抑制的异常数组

## 分析堆栈轨迹元素

堆栈轨迹（stack trace）是程序执行过程中某个特定点上所有挂起的方法调用的一个列表

可以调用Throwable类的printStackTrace方法访问堆栈轨迹的文本描述信息

```java
var t = new Throwable();		//建立一个throwable类对象， 此时其内部存着当前方法的描述
var out = new StringWriter();
t.printStackTrace(new PrintWriter(out));
String description = out.toString();
```

另一种方法是使用StackWalker 类， 其会生成一个StackWalker.StackFrame实例流， 每个实例分别描述一个栈桢（stack frame）

```java
StackWalker walker = StackWalker.getInstance();
walker.forEach(frame -> analyze frame);
```

懒方式则为（使用lambda表达式将forEach放入walk方法中）

```java
walker.walk(stream -> process stream);
```

stackTrace/StackTraceTest.java

```java
package stackTrace;

import java.util.*;

/**
 * A program that display a trace feature of a recursive method call.
 * @author Cay Horstmann
 */
public class StackTraceTest
{
    /**
     * COmputes the factorial of a number
     * @param n a non-negative integer
     * @return n! = 1 * 2 * 3.....* n
     */
    public static int factorial(int n)
    {
        System.out.println("factorial(" + n + "):");
        var walker = StackWalker.getInstance();
        walker.forEach(System.out::println);
        int r;
        if (n <= 1) r = 1;
        else r = n * factorial(n - 1);
        System.out.println("return " + r);
        return r;
    }
    public static void main(String[] args)
    {
        try(var in = new Scanner(System.in))
        {
            System.out.print("Enter n: ");
            int n = in.nextInt();
            factorial(n);
        }
    }
}
```

## API

java.lang.Throwable

* Throwable() 

  onstructs a new throwable with `null` as its detail message.

* Throwable(String message)

  Constructs a new throwable with the specified detail message.

* Throwable(String message, Throwable cause)

  Constructs a new throwable with the specified detail message and cause.

* protected Throwable(String message, Throwable cause, boolean enableSuppression, boolean writableStackTrace)

  Constructs a new throwable with the specified detail message, cause, [suppression](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/lang/Throwable.html#addSuppressed(java.lang.Throwable)) enabled or disabled, and writable stack trace enabled or disabled.

* Throwable(Throwable cause)

  Constructs a new throwable with the specified cause and a detail message of `(cause==null ? null : cause.toString())` (which typically contains the class and detail message of `cause`).

* Throwable initCause(Throwable cause)

  Initializes the *cause* of this throwable to the specified value.

* Throwable getCause() 

  Returns the cause of this throwable or `null` if the cause is nonexistent or unknown.

* StackTraceElement[] getStackTrace()

  Provides programmatic access to the stack trace information printed by [`printStackTrace()`](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/lang/Throwable.html#printStackTrace()).

* void addSuppressed(Throwable exception)

  Appends the specified exception to the exceptions that were suppressed in order to deliver this exception.

* Throwable[]getSuppressed()

  Returns an array containing all of the exceptions that were suppressed, typically by the `try`-with-resources statement, in order to deliver this exception.



java.lang.Exception

* Exception()

  Constructs a new exception with `null` as its detail message.

* Exception(String message)

  Constructs a new exception with the specified detail message.

* Exception(String message, Throwable cause)

  Constructs a new exception with the specified detail message and cause.

* protected Exception(String message, Throwable cause, boolean enableSuppression, boolean writableStackTrace)

  Constructs a new exception with the specified detail message, cause, suppression enabled or disabled, and writable stack trace enabled or disabled.

* Exception(Throwable cause)

  Constructs a new exception with the specified cause and a detail message of `(cause==null ? null : cause.toString())` (which typically contains the class and detail message of `cause`).



java.lang.RuntimeException

* RuntimeException()

  Constructs a new runtime exception with `null` as its detail message.

* RuntimeException(String message)

  Constructs a new runtime exception with the specified detail message.

* RuntimeException(String message, Throwable cause)

  Constructs a new runtime exception with the specified detail message and cause.

* protected RuntimeException(String message, Throwable cause, boolean enableSuppression, boolean writableStackTrace)

  Constructs a new runtime exception with the specified detail message, cause, suppression enabled or disabled, and writable stack trace enabled or disabled.

* RuntimeException(Throwable cause)

  Constructs a new runtime exception with the specified cause and a detail message of `(cause==null ? null : cause.toString())` (which typically contains the class and detail message of `cause`).



java.lang.StackWalker

* void forEach(Consumer<? super StackWalker.StackFrame> action)

  Performs the given action on each element of `StackFrame` stream of the current thread, traversing from the top frame of the stack, which is the method calling this `forEach` method.

* Class<?> getCallerClass()

  Gets the `Class` object of the caller who invoked the method that invoked `getCallerClass`.

* static StackWalker getInstance()

  Returns a `StackWalker` instance.

* static StackWalker getInstance(StackWalker.Option option)

  Returns a `StackWalker` instance with the given option specifying the stack frame information it can access.

* static StackWalker getInstance(Set<StackWalker.Option> options)

  Returns a `StackWalker` instance with the given `options` specifying the stack frame information it can access.

  * The option includes RETAIN_CLASS_REFERENCE, SHOW_HIDDEN-FRAMES and SHOW-REFLECT-FRAMES

* static StackWalker getInstance(Set<StackWalker.Option> options, int estimateDepth)

  Returns a `StackWalker` instance with the given `options` specifying the stack frame information it can access.

* <T> T walk(Function<? super Stream<StackWalker.StackFrame>,? extends T> function)

  Applies the given function to the stream of `StackFrame`s for the current thread, traversing from the top frame of the stack, which is the method calling this `walk` method.



java.lang.StackWalker.StackFrame

* int getByteCodeIndex()

  Returns the index to the code array of the `Code` attribute containing the execution point represented by this stack frame.

* String getClassName()

  Gets the [binary name](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/lang/ClassLoader.html#binary-name) of the declaring class of the method represented by this stack frame.

* Class<?> getDeclaringClass()

  Gets the declaring `Class` for the method represented by this stack frame.

  * if the stack walker is not constructed by RETAIN_CLASS_REFERENCE, it will push a exception.

* default String getDescriptor()

  Returns the *descriptor* of the method represented by this stack frame as defined by The Java Virtual Machine Specification.

* String getFileName()

  Returns the name of the source file containing the execution point represented by this stack frame.

* int getLineNumber()

  Returns the line number of the source line containing the execution point represented by this stack frame.

* String getMethodName()

  Gets the name of the method represented by this stack frame.

* default MethodType getMethodType()

Returns the [`MethodType`](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/lang/invoke/MethodType.html) representing the parameter types and the return type for the method represented by this stack frame.

* boolean isNativeMethod()

Returns `true` if the method containing the execution point represented by this stack frame is a native method.

* StackTraceElement toStackTraceElement()

  Gets a `StackTraceElement` for this stack frame.



java.lang.StackTraceElement

* boolean equals(Object obj)

  Returns true if the specified object is another `StackTraceElement` instance representing the same execution point as this instance.

* String getClassLoaderName()

  Returns the name of the class loader of the class containing the execution point represented by this stack trace element.

* String getClassName()

  Returns the fully qualified name of the class containing the execution point represented by this stack trace element.

* String getFileName()

  Returns the name of the source file containing the execution point represented by this stack trace element.

* int getLineNumber()

  Returns the line number of the source line containing the execution point represented by this stack trace element.

* String getMethodName()

  Returns the name of the method containing the execution point represented by this stack trace element.

* String getModuleName()

  Returns the module name of the module containing the execution point represented by this stack trace element.

* String getModuleVersion()

  Returns the module version of the module containing the execution point represented by this stack trace element.

* int hashCode()

  Returns a hash code value for this stack trace element.

* boolean isNativeMethod()

  Returns true if the method containing the execution point represented by this stack trace element is a native method.

* String toString()

  Returns a string representation of this stack trace element.



# 使用异常的技巧

1. 异常处理不能代替简单的测试， 只在异常情况下使用异常
2. 不要过分细化异常
3. 充分利用异常层次， 应该寻找最适合的子类或自己的异常类
4. 不要压制异常
5. 检查错误时， 苛刻比放任好
6. 不要不愿去传递异常





# 使用断言

## 断言的概念

断言机制允许测试期间向代码插入一些检查， 而在生产代码中会自动删除这些检查。

```java
assert condition;
//or
assert condition : expression;
```



若结果为false， 则抛出一个AssertionError异常， 在第二个语句中， 表达式将传入AssertionError对象构造器中， 并转换成一个消息字符串

若要断言x非负

```java
assert x >= 0;
```

```java
assert x >= 0 : "x >=0";
```

## 启用和禁用断言



使用-ea选项启用断言

```
java -enableassertions Myapp
java -ea:MyClass -ea:com.mycompany.mylib MyApp
```

使用-disableassertions 或-da在某个特定类和包中禁用断言

## 使用断言完成参数检查

1. 断言失败是致命的， 不可修复的错误
2. 断言检查只在开发和测试阶段打开

### API

java.lang.ClassLoader

* void setClassAssertionStatus(String className, boolean enabled)

  Sets the desired assertion status for the named top-level class in this class loader and any nested classes contained therein.

* void setDefaultAssertionStatus(boolean enabled)

  Sets the default assertion status for this class loader.

* void setPackageAssertionStatus(String packageName, boolean enabled)

  Sets the package default assertion status for the named package.

* void clearAssertionStatus()

  Sets the default assertion status for this class loader to `false` and discards any package defaults or class assertion status settings associated with the class loader.



# 日志

## 基本日志

使用**全局日志记录器（global logger）**并调用info方法

```java
Logger.getGlobal().info("File->Open menu item select");
```

若在适当的地方调用

```java
Logger.getGlobal().setLevel(Level.OFF);
```

## 高级日志

调用getLogger方法创建或获取日志记录器

```java
private static final Logger myLogger = Logger.getLogger("com.mycompany.myapp");
```

日志记录器的层次性更强， 如果给一个包设置了日志级别， 其子日志记录器会继承该级别

有以下七个日志级别

* SEVERE
* WARNING
* INFO
* CONFIG
* FINE
* FINER
* FINEST

默认值记录前三个级别

```java
logger.setlevel(Level.FINE);
```

还可以使用Level.ALL开启所有级别日志记录

使用Level.OFF关闭所有级别日志记录

```haijava
logger.warning(message);
logger.fine(message);
```

还可以使用log方法指定级别

```java
logger.log(Level.FINE, message);
```

使用logp方法获得调用类和方法的确切位置

```java
void logp(Level l, String className, String methodName, String message)
```

```java
int read(String file, String pattern)
{
    logger.entering("com.mycompany.mylib.Reader", "read", new Object[] {file, pattern});
    ...
    logger.exiting("com.mycompany.mylib.Reader", "read", count);
    return count;
}
```

这些调用将生成FINER级别以ENTRY和RETURN开头的日志记录

## 修改日志管理器配置

可以通过修改配置文件来修改日志系统的各种属性

在默认日志级别下可以添加自定义的日志记录器的日志级别

```
com.mycompany.myapp.level = FINE
```

若想在控制台看到FINE级别消息， 进行以下设置

```
java.util.logging.ConsoleHandler.level = FINE
```

可以在程序中调用

```java
System.setProperty("java.util.logging.config.file", file);
LogManager.getLogManager().readConfiguration();
```

重新初始化日志管理器

java9可以调用如下方法

```java
LogManager.getLogManager().updateConfiguration(mapper);
```

更新日志配置



## 本地化

本地化的应用程序包含资源包（resource bundle）资源包包含一组映射

一个程序可以包含多个资源包

请求日志记录器时， 可以指定一个资源包

```java
Logger logger = Logger.getLogger(loggerName, "com.mycompany.logmessages");
```

随后为日志消息指定资源包的键

```java
logger.info("readingFile");
```

若需要在本地化消息中添加一些参数， 使用占位符

```
Reading file {0}.
Achtung! Datei {0} wird eingelesen.
```

调用如下方法向占位符传递具体的值

```java
logger.log(Level.INFO, "readingFile", filename);
logger.log(Level.INFO, "renamingFile", new Object[] {old Name, newName});
```

java9可以在logrb方法中指定资源包对象

```java
logger.logrb(Level.INFO, bundle, "renamingFile", oldName, newName);
```



## 处理器

对于一个要记录的日志记录， 其日志级别必须高于日志记录器和处理器二者的阈值

若要记录FINE级别的日志， 需要修改配置文件

```java
Logger logger = Logger.getLogger("com.mycompany.myapp");
logger.setLevel(Level.FINE);
logger.setUseParentHandlers(false);
var handler = new ConsoleHandler();
handler.setLevel(Level.FINE);
logger.addHandler(handler);
```

要想将日志发送到其他地方， 就要添加其他的处理器

```java
var handler = new FileHandler();
logger.addHandler(handler);
```

这些记录发送到用户主目录的Javan.log文件中， 默认记录格式化为XML



还可以扩展Handler类和StreamHandler类自定义处理器

```java

class WindowHandler extends StreamHandler
{
    public WindowHandler()
    {
        ...
        var output =  new JTextArea();
        setOutputStream(new
        OutputStream(){
            public void write(int b) {}   //not called
            public void write(byte []b, int off, int len)
            {
                output.append(new String(b, off, len));
            }
        });
    }
    ...
}
```

使用这种方式处理器会缓存记录， 只有在缓冲区满时，才将他们写入流中， 因此需要覆盖publish方法

```java

class WindowHandler extends StreamHandler
{
    public WindowHandler()
    {
        ...
        var output =  new JTextArea();
        setOutputStream(new
        OutputStream(){
            public void write(int b) {}   //not called
            public void write(byte []b, int off, int len)
            {
                output.append(new String(b, off, len));
            }
        });
    }
    public void publish(LogRecord record)
    {
        super.publish(record);
        flush();
    }
    ...
}
```

## 过滤器

默认情况下， 会根据日志级别进行过滤， 每个日志记录器和处理器都有一个可选的过滤器， 定义过滤器需要实现Filter接口， 并定义以下方法

```java
boolean isLoggable(LogRecord record)
```

要想将一个过滤器安装到日志记录器或处理器中， 调用setFilter方法即可

## 格式化器

ConsoleHandler类和FileHandler类可以生成文本和XML格式日志记录， 但也可以自定义格式， 需要扩展Formatter类并覆盖以下方法：

```java
String format(LogRecord record)
```

最后调用setFormatter方法将格式化器安装进处理器中

## 日志技巧

1. 对一个简单的应用， 可以把日志记录器命名为与主应用包一样的名字
2. 最好在自己应用中安装一个更合适的默认配置
3. 将程序员想要的消息设置为FINE级别是一个很好的选择

logging/LoggingImageViewer.java

```java
package logging;

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.util.logging.*;
import javax.swing.*;


/**
 * A modification of the image viewer program that logs various events.
 * @author Cay Horstmann
 */
public class LoggingImageViewer 
{
    public static void main(String[] args)
    {
        if(System.getProperty("java.util.logging.config.class") == null 
            && System.getProperty("java.util.logging.config.file") == null)
        {
            try
            {
                Logger.getLogger("com.horstmann.corejava").setLevel(Level.ALL);
                final int LOG_ROTATION_COUNT = 10;
                var handler = new FileHandler("%h/LoggingImageViewer.log", 0, LOG_ROTATION_COUNT);
                Logger.getLogger("com.horstmann.corejava").addHandler(handler);
            }
            catch(IOException e)
            {
                Logger.getLogger("com.horstmann.corejava").log(Level.SEVERE, "Can't create log file handler", e);
            }
        }

        EventQueue.invokeLater(() ->
        {
            var windowHandler = new WindowHandler();
            windowHandler.setLevel(Level.ALL);
            Logger.getLogger("com.horstmann.corejava").addHandler(windowHandler);

            var frame = new ImageViewerFrame();
            frame.setTitle("LoggingImageViewer");
            frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

            Logger.getLogger("com.horstmann.corejava").fine("Showing frame");
            frame.setVisible(true);

        });
    }
    
}

/**
 * The frame that shows the image.
 */
class ImageViewerFrame extends JFrame
{
    private static final int DEFAULT_WIDTH = 300;
    private static final int DEFAULT_HEIGHT = 400;

    private JLabel label;
    private static Logger logger = Logger.getLogger("com.horstmann.corjava");

    public ImageViewerFrame()
    {
        logger.entering("ImageViewFrame", "<init>");
        setSize(DEFAULT_WIDTH, DEFAULT_HEIGHT);

        //set up menu bar
        var menuBar = new JMenuBar();
        setJMenuBar(menuBar);

        var menu = new JMenu("File");
        menuBar.add(menu);

        var openItem = new  JMenuItem("Open");
        menu.add(openItem);
        openItem.addActionListener(new FileOpenListener());

        var exitItem = new JMenuItem("Exit");
        menu.add(exitItem);
        exitItem.addActionListener(new ActionListener()
        {
            public void actionPerformed(ActionEvent event)
            {
                logger.fine("Exiting.");
                System.exit(0);
            }
        });


        //use a label to display the images
        label = new JLabel();
        add(label);
        logger.exiting("ImageViewerFrame", "<init>");
    }
    private class FileOpenListener implements ActionListener
    {
        public void actionPerformed(ActionEvent event)
        {
            logger.entering("ImageViewerFrame.FileOpenListener", "actionPerformed", event);

            //set up file chooser

            var chooser = new JFileChooser();
            chooser.setCurrentDirectory(new File("."));

            //accept all files ending with .gif
            chooser.setFileFilter(new javax.swing.filechooser.FileFilter()
            {
                public boolean accept(File f)
                {
                    return f.getName().toLowerCase().endsWith(".gif") || f.isDirectory();
                }
                public String getDescription()
                {
                    return "GIF Images";
                }
            });

            //show file chooser dialog
            int r = chooser.showOpenDialog(ImageViewerFrame.this);
            //if image file accepted, set it as icon of the label
            if(r == JFileChooser.APPROVE_OPTION)
            {
                String name = chooser.getSelectedFile().getPath();
                logger.log(Level.FINE, "Reading file {0}", name);
                label.setIcon(new ImageIcon(name));
            }
            else logger.fine("File open dialog canceled.");
            logger.exiting("ImageViewerframe.FileOpenListener", "actionPerformed");
        }
    }
}


/**
 * A handler for displaying og records in a window.
 */
class WindowHandler extends StreamHandler
{
    private JFrame frame;
    public WindowHandler()
    {
        frame = new JFrame();
        var output = new JTextArea();
        output.setEditable(false);
        frame.setSize(200, 200);
        frame.add(new JScrollPane(output));
        frame.setFocusableWindowState(false);
        frame.setVisible(true);
        setOutputStream(new OutputStream(){
            public void write(int b)
            {
            }   //not called
            public void write(byte[] b, int off, int len)
            {
                output.append(new String(b, off, len));
            }
        });
    }
    public void publish(LogRecord record)
    {
        if (!frame.isVisible()) return;
        super.publish(record);
        flush();
    }
}
```

### API

java.util.logging.Logger

```
static Logger getLogger(String name)
```

Find or create a logger for a named subsystem.

```
static Logger getLogger(String name, String resourceBundleName)
```

Find or create a logger for a named subsystem.

```
void
severe(String msg)
```

Log a SEVERE message.

```
void
warning(String msg)
```

Log a WARNING message.

```
void
info(String msg)
```

Log an INFO message.

```
void
config(String msg)
```

Log a CONFIG message.

```
void
fine(String msg)
```

Log a FINE message.

```
void
finer(String msg)
```

Log a FINER message.

```
void
finest(String msg)
```

Log a FINEST message.

```
void
entering(String sourceClass, String sourceMethod)
```

Log a method entry.

```
void
entering(String sourceClass, String sourceMethod, Object param1)
```

Log a method entry, with one parameter.

```
void
entering(String sourceClass, String sourceMethod, Object[] params)
```

Log a method entry, with an array of parameters.

```
void
exiting(String sourceClass, String sourceMethod)
```

Log a method return.

```
void
exiting(String sourceClass, String sourceMethod, Object result)
```

Log a method return, with result object.

```
void
throwing(String sourceClass, String sourceMethod, Throwable thrown)
```

Log throwing an exception.

```
void
log(Level level, String msg)
```

Log a message, with no arguments.

```
void
log(Level level, String msg, Object param1)
```

Log a message, with one object parameter.

```
void
log(Level level, String msg, Object[] params)
```

Log a message, with an array of object arguments.

```
void
log(Level level, String msg, Throwable thrown)
```

Log a message, with associated Throwable information.

```
void
logp(Level level, String sourceClass, String sourceMethod, String msg)
```

Log a message, specifying source class and method, with no arguments.

```
void
logp(Level level, String sourceClass, String sourceMethod, String msg, Object param1)
```

Log a message, specifying source class and method, with a single object parameter to the log message.

```
void
logp(Level level, String sourceClass, String sourceMethod, String msg, Object[] params)
```

Log a message, specifying source class and method, with an array of object arguments.

```
void
logp(Level level, String sourceClass, String sourceMethod, String msg, Throwable thrown)
```

Log a message, specifying source class and method, with associated Throwable information.

```
void
logrb(Level level, String sourceClass, String sourceMethod, ResourceBundle bundle, String msg, Object... params)
```

Log a message, specifying source class, method, and resource bundle, with an optional list of message parameters.

```
void
logrb(Level level, String sourceClass, String sourceMethod, ResourceBundle bundle, String msg, Throwable thrown)
```

Log a message, specifying source class, method, and resource bundle, with associated Throwable information.

```
Level
getLevel()
```

Get the log Level that has been specified for this Logger.



```
void
setLevel(Level newLevel)
```

Set the log level specifying which message levels will be logged by this logger.

```
Logger
getParent()
```

Return the parent for this Logger.

```
void
setParent(Logger parent)
```

Set the parent for this Logger.

```
Handler[]
getHandlers()
```

Get the Handlers associated with this logger.

```
void
addHandler(Handler handler)
```

Add a log Handler to receive logging messages.

```
void
removeHandler(Handler handler)
```

Remove a log Handler.

```
boolean
getUseParentHandlers()
```

Discover whether or not this logger is sending its output to its parent logger.

```
void
setUseParentHandlers(boolean useParentHandlers)
```

Specify whether or not this logger should send its output to its parent Logger.

```
Filter
getFilter()
```

Get the current filter for this Logger.

```
void
setFilter(Filter newFilter)
```

Set a filter to control output on this Logger.









**java.util.logging.Handler**

```
abstract void
publish(LogRecord record)
```

Publish a `LogRecord`.

```
abstract void
flush()
```

Flush any buffered output.

```
abstract void
close()
```

Close the `Handler` and free all associated resources.

```
Filter
getFilter()
```

Get the current `Filter` for this `Handler`.

```
void
setFilter(Filter newFilter)
```

Set a `Filter` to control output on this `Handler`.

```
Formatter
getFormatter()
```

Return the `Formatter` for this `Handler`.

```
void
setFilter(Filter newFilter)
```

Set a `Filter` to control output on this `Handler`.

```
Level
getLevel()
```

Get the log level specifying which messages will be logged by this `Handler`.

```
void
setLevel(Level newLevel)
```

Set the log level specifying which message levels will be logged by this `Handler`.







**java.util.logging.ConsoleHandler**

```
ConsoleHandler()
```

Create a `ConsoleHandler` for `System.err`.

```
void
close()
```

Override `StreamHandler.close` to do a flush but not to close the output stream.

```
void
publish(LogRecord record)
```

Publish a `LogRecord`.



**java.util.logging.FileHandler**

```
FileHandler()
```

Construct a default `FileHandler`.

```
FileHandler(String pattern)
```

Initialize a `FileHandler` to write to the given filename.

```
FileHandler(String pattern, boolean append)
```

Initialize a `FileHandler` to write to the given filename, with optional append.

```
FileHandler(String pattern, int limit, int count)
```

Initialize a `FileHandler` to write to a set of files.

```
FileHandler(String pattern, int limit, int count, boolean append)
```

Initialize a `FileHandler` to write to a set of files with optional append.

```
FileHandler(String pattern, long limit, int count, boolean append)
```

Initialize a `FileHandler` to write to a set of files with optional append.

```
void
close()
```

Close all the files.

```
void
publish(LogRecord record)
```

Format and publish a `LogRecord`.



**java.util.logging.LogRecord**

```
Level
getLevel()
```

Get the logging message level, for example Level.SEVERE.

```
String
getLoggerName()
```

Get the source Logger's name.

```
ResourceBundle
getResourceBundle()
```

Get the localization resource bundle

```
String
getResourceBundleName()
```

Get the localization resource bundle name

```
String
getMessage()
```

Get the "raw" log message, before localization or formatting.

```
Object[]
getParameters()
```

Get the parameters to the log message.

```
Throwable
getThrown()
```

Get any throwable associated with the log record.

```
String
getSourceClassName()
```

Get the name of the class that (allegedly) issued the logging request.

```
String
getSourceMethodName()
```

Get the name of the method that (allegedly) issued the logging request.

```
long
getMillis()
```

Get truncated event time in milliseconds since 1970.

```
Instant
getInstant()
```

Gets the instant that the event occurred.

```
long
getSequenceNumber()
```

Get the sequence number.

```
long
getLongThreadID()
```

Get a thread identifier for the thread where message originated







**java.util.logging.LogManager**

```
static LogManager
getLogManager()
```

Returns the global LogManager object.

```
void
readConfiguration()
```

Reads and initializes the logging configuration.

```
void
readConfiguration(InputStream ins)
```

Reads and initializes the logging configuration from the given input stream.

```
void
updateConfiguration(InputStream ins, Function<String,BiFunction<String,String,String>> mapper)
```

Updates the logging configuration.

```
void
updateConfiguration(Function<String,BiFunction<String,String,String>> mapper)
```

Updates the logging configuration.



**java.util.logging.Filter**

```
boolean
isLoggable(LogRecord record)
```

Check if a given log record should be published.



**java.util.logging.Formatter**

```
abstract String
format(LogRecord record)
```

Format the given log record and return the formatted string.

```
String
formatMessage(LogRecord record)
```

Localize and format the message string from a log record.

```
String
getHead(Handler h)
```

Return the header string for a set of formatted records.

```
String
getTail(Handler h)
```

Return the tail string for a set of formatted records.

# 调试技巧

1. 用print方法打印各种值

2. 在每一个类中放置一个单独的main方法

3. http://junit.org上查看JUnit

4. 日志代理（logging proxy）

   ```java
   var generator  = new Random()
   {
       public double nextDouble()
       {
           double result = super.nextDouble();
           Logger.getGlobal().info("nextDouble: " + result);
           return result;
       }
   }
   ```

   5. 利用Throwble类中的printStackTrace方法

   6. 若想要记录或显示堆栈轨迹， 可以将其捕获到一字符串中

      ```java
      var out = new StringWriter();
      new throwable().printStackTrack(new PrintWriter(out));
      String decription = out.toString(); 
      ```

   7. 将程序错误记入一个文件会很好用

      ```
      java MyProgram 2> errors.txt
      ```

      若想同时记录System.out和System.err

      ```
      java MyProgram 1> errors.txt 2>&1
      ```

   8.  在System.err中显示未捕获的异常的堆栈轨迹并不是一个理想的方法,可以用静态方法Thread.setDefaultUncaughtExceptionHandler改变未捕获异常的处理器：

      ```java
      Thread.setDefaultUncaughtExceptionHandle(
      	new Thread.UncaughtExceptionHandler()
      	{
      		public void uncaughtException(Thread t, Throwable e)
      		{
      			save information in log file
      		};
      	});
      ```

   9. 要想观察类的加载过程， 启动java虚拟机时可以使用-verbose标志

   10. -Xlint 选项告诉编译器找出常见的代码问题

       ```
       javac -Xlint sourceFiles
       javac -Xlint:all, -fallthrough, -serial sourceFiles
       ```

       可以用以下命令得到所有警告的一个列表

       ```
       javac --help -X
       ```

   11. java虚拟机中增加了对java应用程序的监控（monitoring）和管理(management)

       JDK提供了一个名为jconsole的图形工具

   12. java任务管理器（java Mission Control）

