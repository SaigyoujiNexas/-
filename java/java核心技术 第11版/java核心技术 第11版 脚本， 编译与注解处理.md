# java平台的脚本机制

脚本API可以在Java平台上对各种脚本语言进行调用

## 获取脚本引擎

需要构造一个ScriptEngineManager, 并调用getEngineFactories方法。

| 引擎                  | 名字                                                         | MIME类型                                                     | 文件扩展   |
| --------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ---------- |
| Nashorn( 包含在jdk中) | nashorn， Nashorn, js, JS, JavaScript, javascript, ECMAScript, ecmascript | application/javascript, application/ecmascript, text/javascript, text/ecmascript | js         |
| Groovy                | groovy                                                       | 无                                                           | groovy     |
| Renjin                | Renjin                                                       | text/x-R                                                     | R, r, S, s |

```java
ScriptEngine engine = manager.getEngineByName("nashorn");
```

## 脚本计算与绑定

当拥有了引擎， 就可以通过如下调用来直接调用脚本

```java
Object result = engine.eval(scriptString);
```

如果脚本存在文件中， 就先需要打开一个Reader， 然后调用

```java
Object result = engine.eval(reader);
```

可以在同一个引擎上调用多个脚本， 若一个脚本定义了变量， 函数或类， 那么大多数引擎都会保留这些定义， 以供将来使用

```java
engine.eval("n = 1728");
Object result = engine.eval("n + 1");
```

偌要想知道在多个线程中并发执行脚本是否安全， 可以调用

```java
Object param = factory.getParameter("THREADING");
```

返回值如下

* null : 不安全
* "MULTITHREAD": 并发执行安全
* "THREAD-ISOLATED": 除了并发执行安全， 还会为每个线程维护不同的变量绑定
* "STATELESS": 脚本不会改变变量绑定

向引擎添加新的变量绑定

```java
engine.put("k", 1728);
Object result = engine.eval("k + 1");
```

脚本代码从引擎作用域中的绑定里读取k的定义， 因为大多数脚本语言可以访问java对象， 所以

```java
engine.put("b", new JButton());
engine.eval("b.text = 'OK'");
```

反过来， 亦可以获取由脚本语句绑定的变量

```java
engine.eval("n = 1728");
Object result = engine.get("n");
```

除了脚本作用域， 还有全局作用域。任何添加到ScriptEngineManager中的绑定对所有引擎都是可视的。

除了向引擎或全局作用域添加绑定外， 还可以将绑定收集到一个Bindings的对象中， 然后传递给eval方法

```java
Bindings scope = engine.createBindings();
scope.put("b", new JButton());
engine.eval(scriptString, scope);
```

## 重定向输入和输出

调用setReader和setWriter方法来重定向脚本的标准输入和输出

```java
var writer = new StringWriter();
engine.getContext().setWriter(new PrintWriter(writer, true));
```

println("Hello"); 会被重定义

Nashorn引擎没有标准输入源的概念， 调用setReader没有效果

## 调用脚本的函数和方法

提供可以调用脚本语言的函数的脚本引擎实现了invocable接口

要调用一个函数， 需要用函数名来调用invokeFunction方法， 函数名后面是函数的参数；

```java
//Define greet function in JavaScript
engine.eval("function greet(how, whom) {return how + ', ' + whom + '!'}");

//Call the function with arguments "Hello", "World"
result = ((Invocable) engine).invokeFunction("greet", "Hello", "World");
```

若脚本语言是面向对象的， 则调用invokeMethod

```java
//Define Greeter class in JavaScript
engine.eval("function Greeter(how){this.how = how}");
engine.eval("Greeter.prototype.welcome= function(whom){return this.how + ', ' + whom + '!' }");

//Construct an instance
Object yo = engine.eval("new Greeter('Yo')");

//Call the welcome method on the instance
result = ((Invocable) engine).invokeMethod(yo, "welcome", "World");
```

还可以让一个脚本语言去实现java的接口， 然后用java方法调用的语法来调用脚本函数

如果在Nashorn中定义了相同名字的函数， 那么可以通过这个接口调用

```java
public interface Greeter
{
    String welcome(String whom);
}
// Define welcome function in JavaScript
engine.eval("function welcome(whom) {return 'Hello, ' + whom + '!'}");

//Get a Java object and call a Java method
Greeter g = ((Invocable) engine).getInterface(Greeter.class);
result = g.welcome("World");
```

在面向对象的脚本语言中， 可以通过一个相匹配的Java接口来访问一个脚本类

```java
Greeter g = ((Invocable)engine).getInterface(yo, Greeter.class);
result = g.welcome("World");
```

## 编译脚本

可以将脚本代码编译为某种中间格式的引擎实现了Compilable接口

```java
var reader = new FileReader("myscript.js");
CompileScript script = null;
if (engine implements Compilable)
    script = ((Compilable) engine).compile(reader);
```

一旦脚本被编译就可以被执行

```java
if(script != null)
    script.eval();
else
    engine.eval(reader);
```

不过， 也就是在希望重复执行时， 才希望去编译该脚本。

## 示例： 用脚本处理GUI事件

```java
package script;

import javax.script.ScriptEngine;
import javax.script.ScriptEngineFactory;
import javax.script.ScriptEngineManager;
import javax.script.ScriptException;
import javax.swing.*;
import java.awt.*;
import java.beans.EventSetDescriptor;
import java.beans.IntrospectionException;
import java.beans.Introspector;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

/**
 * @author Cay Horstmann
 */
public class ScriptTest {
    public static void main(String[] args) {
        EventQueue.invokeLater(() -> {
            try{
                var manager = new ScriptEngineManager();
                String language;
                if(args.length == 0)
                {
                    System.out.println("Available factories: ");
                    for (ScriptEngineFactory factory : manager.getEngineFactories())
                        System.out.println(factory.getEngineName());
                    language = "nashorn";
                }
                else language = args[0];
                final ScriptEngine engine = manager.getEngineByName(language);
                if(engine == null) {
                    System.err.println("No engine for " + language);
                    System.exit(1);
                }

                final String frameClassName = args.length < 2? "buttons1.ButtonFrame" : args[1];
                var frame = (JFrame) Class.forName(frameClassName).getConstructor().newInstance();
                InputStream in = frame.getClass().getResourceAsStream("init." + language);
                if(in != null) engine.eval(new InputStreamReader(in));
                var components = new HashMap<String, Component>();
                getComponentBindings(frame, components);
                components.forEach((name, c) -> engine.put(name, c));

                var events = new Properties();
                in = frame.getClass().getResourceAsStream(language + ".properties");
                events.load(in);
                for(Object e: events.keySet())
                {
                    String[] s = ((String) e).split("\\.");
                    addListener(s[0], s[1], (String) events.get(e), engine, components);
                }
                frame.setTitle("ScriptTest");
                frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
                frame.setVisible(true);
            }
            catch (ReflectiveOperationException | IOException | ScriptException | IntrospectionException ex)
            {
                ex.printStackTrace();
            }
        });
    }

    /**
     * Gathers all named components in a container
     * @param c the component
     * @param namedComponents a map into which to enter the component names and components
     */
    private static void getComponentBindings(Component c, Map<String, Component> namedComponents)
    {
        String name = c.getName();
        if(name != null) {namedComponents.put(name, c);}
        if(c instanceof Container)
        {
            for(Component child: ((Container) c).getComponents())
                getComponentBindings(child, namedComponents);
        }
    }
    /**
     * Adds a listener to an object whose listener method executes a script.
     * @param beanName the name of the bean to which the listener should be added
     * @param eventName the name of the listener type, such as "action" or "change"
     * @param scriptCode the script code to be executed
     * @param engine the engine that executes the code
     * @throws java.beans.IntrospectionException
     */
    private static void addListener(String beanName, String eventName, final String scriptCode,
                                    ScriptEngine engine, Map<String, Component> components) throws ReflectiveOperationException, IntrospectionException
    {
        Object bean = components.get(beanName);
        EventSetDescriptor descriptor = getEventDescriptor(bean, eventName);
        if(descriptor == null) return;
        descriptor.getAddListenerMethod().invoke(bean, Proxy.newProxyInstance(null, new Class[]{descriptor.getListenerType()},
                (proxy, method, args) -> {
                    engine.eval(scriptCode);
                    return null;
                }));
    }

    private static EventSetDescriptor getEventDescriptor(Object bean, String eventName) throws IntrospectionException
    {
        for(EventSetDescriptor descriptor: Introspector.getBeanInfo(bean.getClass()).getEventSetDescriptors())
            if(descriptor.getName().equals(eventName)) return  descriptor;
        return null;
    }
}
```

```java
package buttons1;

import javax.swing.*;
import java.awt.*;

/**
 * A frame with a button panel.
 * @author Cay Horstmann
 */
public class ButtonFrame extends JFrame {
    public static final int DEFAULT_WIDTH = 300;
    public static final int DEFAULT_HEIGHT  = 200;

    private JPanel panel;
    private JButton yellowButton;
    private JButton blueButton;
    private JButton redButton;

    public ButtonFrame()
    {
        setSize(DEFAULT_WIDTH, DEFAULT_HEIGHT);

        panel = new JPanel();
        panel.setName("panel");
        add(panel);

        yellowButton = new JButton("Yellow");
        yellowButton.setName("yellowButton");
        blueButton = new JButton("blue");
        blueButton.setName("blueButton");
        redButton = new JButton("Red");
        redButton.setName("redButton");

        panel.add(yellowButton);
        panel.add(blueButton);
        panel.add(redButton);
    }
}
```

```javascript
yellowButton.action=panel.background = java.awt.Color.YELLOW
blueButton.action=panel.background = java.awt.Color.BLUE
redButton.action=panel.background = java.awt.Color.RED
```



# 编译器API

## 调用编译器

```java
JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
OutputStream outStream = ...;
OutputStream errStream = ...;
int result = compiler.run(null, outStream, errStream, "-sourcepath", "src", "Test.java");
```

返回值为0即编译成功

run方法第一个参数是输入流， 应该让其总是保持为null

## 发起编译任务

使用CompilationTask对象来对编译过程进行更多的控制。 

```java
JavaCompiler.CompilationTask task = compiler.getTask(
errorWriter,  //Uses System.err if null
fileManager,  //Uses the standard file manager if null
diagnostics,  //Uses System.err if null
options		//null if no options
classes, 	//For annotation processing; null if nuno
sources);
```

最后三个参数是Iterable的实例

```java
Iterable<String> options = List.of("-d", "bin");
```

sources参数是JavaFileObject 实例的Iterable， 若想要编译一个磁盘文件， 需要获取一个StandardJavaFileManager对象， 并调用getJavaFileObjects 方法；

```java
StandardJavaFileManager fileManager = compiler.getStandardFileManager(null. null, null);
Iterable<JavaFileObject> sources
    = fileManager.getJavaFileObjectsFromString(List.of("File1.java", "File2.java"));
JavaCompiler.CompilationTask task = compiler.getTask(null, null, null, options, null, sources);
```

classes参数仅用于注解处理， 这种情况下还需要一个Processor对象的列表来调用task.processors(annotationProcessors)。

getTask 方法会返回task对象， 但不会启动编译过程， CompilationTask类扩展了Callable< Boolean > , 可以穿给一个ExecutorService并行运行， 或者同步call

```java
Boolean success = task.call();
```



## 捕获诊断信息

需要安装一个DiagnosticListener, 这个监听器在编译器报错或警告时收到一个Diagnostic对象。DiagnosticCollector类实现了这个接口

```java
DiagnosticCollector<JavaFileObject> collector = new DiagnosticCollector<>();
compiler.getTask(null, fileManager, collector, null, null, sources).call();
for(Diagnostic<? extends JavaFileObject> d : collector.getDiagnostics())
{
    system.out.println(d);
}
```

Diagnostic对象包含有关问题位置的信息， 还可以在标准FileManager上安装一个DiagnosticListener对象, 就可以捕获到有关文件缺失的报错

```java
StandardJavaFileManager fileManager = compiler.getStandardFileManager(diagnostic, null, null);
```

## 从内存中读取源文件

若动态生成了源代码， 就可以从内存中获取并进行编译， 而无需在磁盘保存

```java
public class StringSource extends SimpleJavaFileObject
    {
        private String code;
        StringSource(String name, String code)
        {
            super(URI.create("string:///" + name.replace('.', '/') + ".java"), Kind.SOURCE);
            this.code = code;
        }
        public CharSequence getCharContent(boolean ignoreEncodingErrors)
        {
            return code;
        }
    }
```

然后， 生成类的代码， 并提交给编译器一个StringSource的对象的列表

```java
List<StringSource> sources = List.of(new StringSource(className1, class1CodeString), ...);
task = compiler.getTask(null,filemanager, diagnostics, null, null, sources);
```

## 将字节码写出到内存

首先要有一个类持有字节

```java
public class ByteArrayClass extends SimpleJavaFileObject
    {
        private ByteArrayOutputStream out;
        ByteArrayClass(String name)
        {
            super(URI.create("string:///" + name.replace('.', '/') + ".class"), Kind.CLASS);
        }
        public byte[] getCode()
        {
            return out.toByteArray();
        }
        public OutputStream openOutputStream() throws IOException
        {
            out = new ByteArrayOutputStream();
            return out;
        }
    }
```

接下来需要将文件管理器配置为使用这些类作为输出

```java
List<ByteArrayClass> classes = new ArrayList<>();
StandardJavaFileManager stdFileManager = compiler.getStandardFileManager(null, null, null);
JavaFileManager fileManager = new ForwardingJavaFileManager<JavaFileManager>(stdFileManager)
{
    public JavaFileObject getJavaFileForOutput(Location location, String className, Kind kind, FileObject sibling) throws IOException
    {
        if(kind == Kind.CLASS)
        {
            ByteArrayClass outfile = new ByteArrayClass(className);
            classes.add(outfile);
            return outfile;
        }
        else
            return super.getJavaFileForOutput(location, className, kind, sibling);
    }
 }
```

为了加载这些类， 使用类加载器

```java
public class ByteArrayClassLoader extends ClassLoader
{
    private Iterable<ByteArrayVClass> classes;
    public ByteArrayClassLoader(Iterable<ByteArrayClass> classes)
    {
        this.classes = classes;
    }
    
    public Class<?> findClass(String name) throws ClassNotFoundException
    {
        for(ByteArrayClass cl: classes)
        {
            if(cl.getName().equals("/" + name.replace('.', '/') + ".class"))
            {
                byte[] bytes = cl.getCode();
                return defineClass(name, bytes, 0, bytes.length);
            }
        }
        throw new ClassNotFoundException(name);
    }
}
```



编译完成后用上面的类加载器调用Class.forName方法：

``` java
ByteArrayClassLoader loader = new ByteArrayClassLoader(classes);
Class<?> cl = Class.forName(className, true, loader);
```

## 示例： 动态Java代码生成





