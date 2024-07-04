# JVM内存管理

C语言动态申请内存方法如下

```c
#include <stdlib.h>
#include <stdio.h>

int main(){
    int * memory = malloc(sizeof(int) * 4);
    memory[0] = 10;
    memory[1] = 2;
    
    for(int i = 0; i < 4; i++){
        printf("%d ", memory[i]);
    }
    free(memory);
    memory = NULL;
}
```

Java中内存申请与释放则有JVM进行管理。

## 内存区域划分

JVM采用分区管理

![image-20220811172030836](https://s2.loli.net/2022/08/11/oNYke7QwJTKaLxq.png)

### 程序计数器

程序计数器存储当前代码执行到的位置，字节码解释器将会解释当前行代码，并且指定下一行代码。

Java的多线程依靠时间片轮转算法。所有的线程的执行位置存储在程序计数器中。 

### 虚拟机栈

每个方法被执行时都会创建一个栈帧，包括了方法的局部变量表，操作树栈，动态链接，方法出口等。每个栈帧还保存了可以指向**当前方法所在类**的运行时常量池， 方便动态链接。

对于该java代码

```java
public class Main{
	public static void main(String...args){
		int res  = a();
		System.out.println(res);
	}

	public static int a(){
		return b();
	}

	public static int b(){
		return c();
	}
	public static int c(){
		int a = 10;
		int b = 20;
		return a + b;
	}


}
```

反编译字节码如下：

```java
Classfile /home/yuki/dev/java/test/Main.class
  Last modified Aug 11, 2022; size 574 bytes
  SHA-256 checksum b5e81768b0ee2f77ae5dcb60e412a22cd0d5d1dedd02420ced1e8691b3dbb1fc
  Compiled from "Main.java"
public class Main
  minor version: 0
  major version: 61
  flags: (0x0021) ACC_PUBLIC, ACC_SUPER
  this_class: #8                          // Main
  super_class: #2                         // java/lang/Object
  interfaces: 0, fields: 0, methods: 5, attributes: 1
Constant pool:
   #1 = Methodref          #2.#3          // java/lang/Object."<init>":()V
   #2 = Class              #4             // java/lang/Object
   #3 = NameAndType        #5:#6          // "<init>":()V
   #4 = Utf8               java/lang/Object
   #5 = Utf8               <init>
   #6 = Utf8               ()V
   #7 = Methodref          #8.#9          // Main.a:()I
   #8 = Class              #10            // Main
   #9 = NameAndType        #11:#12        // a:()I
  #10 = Utf8               Main
  #11 = Utf8               a
  #12 = Utf8               ()I
  #13 = Fieldref           #14.#15        // java/lang/System.out:Ljava/io/PrintStream;
  #14 = Class              #16            // java/lang/System
  #15 = NameAndType        #17:#18        // out:Ljava/io/PrintStream;
  #16 = Utf8               java/lang/System
  #17 = Utf8               out
  #18 = Utf8               Ljava/io/PrintStream;
  #19 = Methodref          #20.#21        // java/io/PrintStream.println:(I)V
  #20 = Class              #22            // java/io/PrintStream
  #21 = NameAndType        #23:#24        // println:(I)V
  #22 = Utf8               java/io/PrintStream
  #23 = Utf8               println
  #24 = Utf8               (I)V
  #25 = Methodref          #8.#26         // Main.b:()I
  #26 = NameAndType        #27:#12        // b:()I
  #27 = Utf8               b
  #28 = Methodref          #8.#29         // Main.c:()I
  #29 = NameAndType        #30:#12        // c:()I
  #30 = Utf8               c
  #31 = Utf8               Code
  #32 = Utf8               LineNumberTable
  #33 = Utf8               main
  #34 = Utf8               ([Ljava/lang/String;)V
  #35 = Utf8               SourceFile
  #36 = Utf8               Main.java
{
  public Main();
    descriptor: ()V
    flags: (0x0001) ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 1: 0

  public static void main(java.lang.String...);
    descriptor: ([Ljava/lang/String;)V
    flags: (0x0089) ACC_PUBLIC, ACC_STATIC, ACC_VARARGS
    Code:
      stack=2, locals=2, args_size=1
         0: invokestatic  #7                  // Method a:()I
         3: istore_1
         4: getstatic     #13                 // Field java/lang/System.out:Ljava/io/PrintStream;
         7: iload_1
         8: invokevirtual #19                 // Method java/io/PrintStream.println:(I)V
        11: return
      LineNumberTable:
        line 3: 0
        line 4: 4
        line 5: 11

  public static int a();
    descriptor: ()I
    flags: (0x0009) ACC_PUBLIC, ACC_STATIC
    Code:
      stack=1, locals=0, args_size=0
         0: invokestatic  #25                 // Method b:()I
         3: ireturn
      LineNumberTable:
        line 8: 0

  public static int b();
    descriptor: ()I
    flags: (0x0009) ACC_PUBLIC, ACC_STATIC
    Code:
      stack=1, locals=0, args_size=0
         0: invokestatic  #28                 // Method c:()I
         3: ireturn
      LineNumberTable:
        line 12: 0

  public static int c();
    descriptor: ()I
    flags: (0x0009) ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=2, args_size=0
         0: bipush        10
         2: istore_0
         3: bipush        20
         5: istore_1
         6: iload_0
         7: iload_1
         8: iadd
         9: ireturn
      LineNumberTable:
        line 15: 0
        line 16: 3
        line 17: 6
}
SourceFile: "Main.java"
```

### 本地方法栈

为本地方法准备的栈。

### 堆

负责存放和管理对象，GC也主要作用于该区域。

### 方法区

用于存储所有的类信息，常量，静态变量，动态编译缓存等数据。有类信息表和运行时常量池两个部分。

![image-20220811180142315](https://s2.loli.net/2022/08/11/T7mMdZYKQyXz8Oh.png)

类信息表存放的是当前应用加载的所有类信息，同时将编译生成的常量池数据放入运行时常量池中。当然程序运行时也有可能会有新的常量进入常量池。

```java
public class Main{
    public static void main(String...args){
        String str1 = new String("abc");
        String str2 = new String("abc");
        
        System.out.println(str1 == str2);		//false
        System.out.println(str1.equals(str2));	//true
    }
}
```

这里是因为str1和str2都是单独创建的对象。

![image-20220811180933839](https://s2.loli.net/2022/08/11/zI8P5chdMt1TOp9.png)

```java
public class Main{
    public static void main(String...args){
        String str1 = "abc";
        String str2 = "abc";
        
        System.out.println(str1 == str2);		//true
        System.out.println(str1.equals(str2));	//true
    }
}
```

因为没有使用new，这时str1和str2所指向的内存地址是一样的。

![image-20220811181621115](https://s2.loli.net/2022/08/11/6HfWe7wGPCqFOVD.png)

```java
public class Main{
    public static void main(String...args){
        String str1 = new String("abc");
        String str2 =new String("abc");
        
        System.out.println(str1.intern() == str2.intern());		//true
        System.out.println(str1.equals(str2));	//true
    }
}
```

intern方法会在常量池中查找该字符串，当常量池中没有对应字符串时，在常量池中创建一个指向当前字符串堆中的引用。

```java
public class Main{
    public static void main(String...args){
        String str1 = new String("ab") + new String("c");
        String str2 = new String("ab") + new String("c");
        
        System.out.println(str1.intern() == str2.intern());		//true
        System.out.println(str1.equals(str2));	//true
    }
}
```

![image-20220811182934440](https://s2.loli.net/2022/08/11/RXlQuGkDKTPgt4M.png)





```java
public class Main{
    public static void main(String...args){
        String str1 = new String("ab") + new String("c");
        
        System.out.println(str1.intern() == str1);		//true
    }
}
```

## 内存不足

```java
public static void main(String...args){
    int[] a = new int[Integer.MAX_VALUE];
}
```

可能就会抛出OutOfMemoryError。通常可以通过参数控制最大堆内存和最小堆内存

```bash
java -Xms最小值 -Xmx最大值 xxx.java
```

如下命令可以在溢出时保存堆转储 快照

```java
-XX:+HeapDumpOnOutOfMemoryError
```

```java
public class Main(){
    public static void main(String...args){
        test();
    }
    public static void test(){
        test();
    }
}
```

会抛出StackOverflowError。

可以使用-Xss设定栈容量

## 申请堆外内存

本质上是JVM调用本地malloc函数申请的内存，需要自己手动释放。

通过Unsafe类反射调用获得

```java
public final class Unsafe{
    private static native void registerNatives();
    static{
        registerNatives();
        sun.reflect.Reflection.registerMethodsToFilter(Unsafe.class, "getUnsafe");
    }
    
    private Unsafe(){}
    
    private static final Unsafe theUnsafe = new Unsafe();
    
    @CallerSensitive
    public static Unsafe getUnsafe(){
        Class<?> caller = Reflection.getCallerClass();
        if(!VM.isSystemDomainLoader(caller.getClassLoader()))
            throw new SecurityException("Unsafe") //不是JDK的类不让用
        return theUnsafe;
    }
}
```

```java
public static void main(String...args) throws IllegalAccessException{
    Field unsafeField = Unsafe.class.getDeclaredFields()[0];
    unsafeField.setAccessible(true);
    Unsafe unsafe = (Unsafe) unsafeField.get(null);
    
    long address = unsafe.allocateMemory(4);
    unsafe.putInt(address, 66666666);
    System.out.println(unsafe.getInt(address));
    unsafe.freeMemory(address);
    System.out.println(unsafe.getInt(address));
}
```



# 垃圾回收机制

## 对象存活判定

### 引用计数法

每个对象包含一个**引用计数器**，用于存放引用计数。引用计数为0时，表示对象不可能再被引用。

对于成环引用，引用计数则会出现一些问题。

```java
public class Main{
    public static void  main(String[] args){
        Test a = new Test();
        Test b = new Test();
        a.another = b;
        b.another = a;
        
        a = b = null;
    }
    private static class Test{
        Test another;
    }
}
```

由于成环引用，导致引用计数始终为1。

### 可达性分析算法

每个对象的引用都有机会成为树的根节点（GC Roots）

* 位于虚拟机栈的栈帧中的本地变量表所引用到的对象，同样也包括JNI引用中的对象
* 类的静态成员变量引用的对象。
* 方法区中，常量池引用的对象
* 被添加了锁的对象
* VM内部需要用到的对象

![image-20220811214920090](https://s2.loli.net/2022/08/11/5IrXOQFGxhJqAow.png)

一旦已经存在的根节点不满足存在的条件时，那么根节点与对象之间的连接将断开。

![image-20220811215129260](https://s2.loli.net/2022/08/11/1Mkeawt7Lgis9RH.png)

对于刚才上述情况：

![image-20220811215306632](https://s2.loli.net/2022/08/11/sA9OqGyW3lfi1Sx.png)

![image-20220811215319838](https://s2.loli.net/2022/08/11/RTMSlqaFN3tVmvs.png)

如果每个对象都不能到达任何GCRoots，则证明该对象不可被继续引用。

### 最终判定

若重写了finalize方法，当子类可被回收时，运行finalize方法，在finalize方法中，当前对象是可能重建GC Roots的。

```java
public class Main{
	private static Test a;
	public static void main(String[] args) {
		a = new Test();

		a = null;
		System.gc();
        Thread.sleep(1000);
		System.out.println(a);
	}
	private static class Test{
		@Override
		protected void finalize() throws Throwable {
			System.out.println(this + " 开始了她的救赎之路！");
			a = this;
		}
	}
}
```

finalize方法其实是用来辅助释放额外资源的，这种防止gc的操作不推荐。

finalize方法在Finalizer线程中运行。

同时，finalize方法每个对象只会运行一次。如果连续两次触发gc，则必定被回收。



![image-20220812153657131](https://s2.loli.net/2022/08/12/twGu5Vc8Rx6hqZC.png)

## 垃圾回收算法

### 分代管理机制

Java虚拟机将堆内存分为新生代，老年代和永久代。

在HotSpot虚拟机中新生代分为三块，一块较大的Eden空间和两块较小的Survivor空间，默认比例8：1：1。老年代GC频率较低，永久代一般存放类信息。

![image-20220812154256817](https://s2.loli.net/2022/08/12/fpj5LWnchNbECi1.png)

所有新创建的对象都会进入新生代Eden区(大对象放在老年代)。新生代区域的GC会对新生代区域所有对象进行扫描，并回收不再使用的对象。

![image-20220812154515036](https://s2.loli.net/2022/08/12/7NfM1QrxzOhwjZJ.png)

在一次GC后Eden区没有回收的对象进入Survivor区，GC之后，所有Eden区存活对象进入From区，最后From和To区进行一次交换。

![image-20220812154715835](https://s2.loli.net/2022/08/12/gfVC38aFYWcUBjE.png)

下一次GC时，会对To区进行年龄判定，若年龄大于默认值15，直接进入老年代，否则进入From区。

![image-20220812155019969](https://s2.loli.net/2022/08/12/6LCMbz3J71DrgQR.png)

随后From区和To区交换。

GC分为以下几种

* Minor GC - 次要垃圾回收，主要进行新生代区域GC， 触发条件：Eden区域满
* Major GC - 主要垃圾回收， 主要进行老年代区域GC
* Full GC - 完全垃圾回收，整个Java堆内存和方法区进行垃圾回收。
  * 触发条件1： 每次进入老年代的对象平均大小大于老年代剩余空间
  * 触发条件2： Minor GC后存活对象超过老年代剩余空间
  * 触发条件3： 手动调用System.gc()
  * 触发条件4：永久代内存不足

使用-XX:+PrintGCDetails参数打印GC日志。

### 空间分配担保

在一次GC后， 若Eden区仍然存在大量对象，Survivor区无法容纳，则把这些对象直接移入老年代。若老年代无法容纳，则会先判断之前每次GC进入老年代的平均大小是否小于当前老年代剩余空间，若小于，则进行一个Full GC，再次判断是否可以容纳，如果仍无法容纳，则抛出OOM错误。

![image-20220812160444363](https://s2.loli.net/2022/08/12/EXzLuxIv5pRrf9d.png)

### 标记-清除算法

首先标记所有需要回收的对象，然后依次回收被标记的对象。

![image-20220812160919121](https://s2.loli.net/2022/08/12/la9trKgqEmJ8s3Z.png)

### 标记-复制算法

每次GC后，将所有存活对象移动入另一块区域，并一次性清空当前区域，浪费了一些时间进行复制，但是解决了空间碎片化的问题

![image-20220812161132664](https://s2.loli.net/2022/08/12/mSBivOegz4Hckl5.png)

新生代的Survivor区采用的就是该思路

### 标记-整理算法

在标记所有待回收对象后，先进行一个排序，然后直接清除后半部分。

![image-20220812161334446](https://s2.loli.net/2022/08/12/qjHz7cpI8hvl3Nu.png)

这种算法效率非常低，可能导致程序卡顿(Stop the World)

## 垃圾回收器实现

### Serial收集器

这是一个单线程垃圾收集器，开始垃圾回收时，需要暂停所有线程。其新生代采用标记-复制算法，老年代采用标记-整理算法。

![image-20220813202824545](https://s2.loli.net/2022/08/13/HzLXkDeEuKNoOfp.png)

其优势：

* 设计简单高效。
* 用户桌面场景下，内存一般不大，可以在较短时间完成垃圾收集。

客户端模式下的垃圾收集器现在仍为Serial收集器。

### ParNew收集器

相当于Serial的多线程版本。

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gzn9vbvb0mj21c20c00uc.jpg&sign=85fc117b2ce4564564b531a65b116ab7c112bc1ea2df3b73046574af10435aa3)

一部分JVM默认的Server端模式的新生代收集器采用ParNew收集器

### Parallel Scavenge/Parallel Old 收集器

Parallel Scavenge 为面向新生代的垃圾收集器，采用标记复制算法。JDK6时推出了Parallel Old的老年代收集器，采用标记整理算法。

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gzna31mo1qj21cs0ckjt3.jpg&sign=44f6fe6a1459c75759360eb0b6974c61710ca064ad37494c07878ab4b750469d)

其与ParNew不同的是其会自动衡量吞吐量

JDK8采用了Parallel Scavenge + Parallel Old收集器

### CMS收集器

在JDK1.5推出的收集器，是HotSpot虚拟机的真正意义上的并发收集器(同时运行GC线程和用户线程)

主要采用标记清除算法。

![51d69260-b91b-4fcf-b15a-1a500456fa86](https://s2.loli.net/2022/08/13/qB4dRptSGCwX18F.jpg)

分为如下4个阶段：

* 初始标记（需要暂停用户线程）：仅标记出能与GC Roots直接关联的对象，速度比较快。
* 并发标记：从GC Roots的直接关联对象开始遍历对象图的过程，耗时较长但不需要停顿用户线程、
* 重新标记（需要暂停用户线程）：进行一次重新标记，来标记在并发标记阶段新创建的对象
* 并发清理：将无用对象进行清理

缺点：标记清除算法会产生大量内存碎片，会有更高的Full GC触发几率



### Garbage First (G1) 收集器

 JDK9后续版本采用该回收器。

G1收集器将整个堆空间分为2048个Region快，每个Region块控制在1-32Mb之间，且都为2^n大小。每个Region块自由决定扮演Eden，Servivor或老年代的角色，收集器根据对应角色使用不同回收策略。G1收集器还存在一个Humongous区域，存放大对象（一般认为超过Region块一半大小）

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gznc9jvdzdj21f40eiq4g.jpg&sign=5b8e726b7f3f8b0b36290b3b664bff8387916fefb5d543e6cd67d2119d99cc01)

回收过程如下：

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gznc8vqqqij21h00emwgt.jpg&sign=e5adcfb964a6acd9f562802c3f1ab4c3aaa18974045e446db35e1ac2b0ad3a3b)

分为以下四阶段：

* 初始标记（暂停用户线程）:标记与GC Roots直接关联的对象。
* 并发标记：遍历堆中的对象图
* 最终标记：标记并发期间漏标的部分对象
* 筛选回收：负责更新Region区域的统计数据，对回收性价比进行排序，根据用户时间制定回收策略。将决定回收的回收集中的存活对象移动到空的Region区域后，清空旧Region区。（移动操作需要暂停用户线程）

## 元空间(MetaSpace)

JDK8之后将类的元信息存储在元空间中。理论上元空间大小只受物理内存大小影响。

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gznd3pdzvyj21q20fcacr.jpg&sign=5b14bae633d6a70ba54af2815f6ff4a6540e78605fe5a94427d29504c4c6366e)

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gzncp6mhikj21ik0migqv.jpg&sign=fb8ee6dda535342e2d8284e04d587babd78c0fd48451ac91b8672bb0b8e0c1e5)

## 其他引用类型

Java提供了额外三种引用类型

### 软引用

当JVM认为内存不足时，会去试图回收软引用

```java
public class Main{
    public static void main(String...args){
        var reference = new SoftReference<>(new Object());
        System.out.println(reference.get());
    }
}
```

软引用构造时还可以传入一个ReferenceQueue

```java
public class Main{
    public static void main(String...args){
        ReferenceQueue<Object> queue = new ReferenceQueue<>();
        var reference = new SoftReference<Object>(new Object(), queue);
        System.out.println(reference);
        
        try{
            List<String> list = new ArrayList<>();
            while(true) list.add(new String("lbwnb"));
        }catch(Throwable t){
            System.out.println("发生了内存溢出！"+t.getMessage());
            System.out.println("软引用对象："+reference.get());
            System.out.println(queue.poll());
        }
    }
}
```

### 弱引用

进行GC时回收引用

```java
public class Main {
    public static void main(String[] args) {
        SoftReference<Object> softReference = new SoftReference<>(new Object());
        WeakReference<Object> weakReference = new WeakReference<>(new Object());

        //手动GC
        System.gc();

        System.out.println("软引用对象："+softReference.get());
        System.out.println("弱引用对象："+weakReference.get());
    }
}
```

WeakHaspMap则基于该样式，当Map中的Key没有其他引用时，清除该键值对

```java
public class Main{
    public static void main(String...args){
        var a = new Integer(1);
        
        var map = new WeakHashMap<Integer, String>();
        map.put(a, "yyds");
        System.out.println(map);
        
        a = null;
        System.gc();
        
        System.out.println(map);
    }
}
```

当a断开后，键值对自动舍弃。通常比较适合用来做缓存机制。

### 虚引用

相当于没有引用

```java
public class PhantomReference<T> extends Reference<T> {

    /**
     * Returns this reference object's referent.  Because the referent of a
     * phantom reference is always inaccessible, this method always returns
     * <code>null</code>.
     *
     * @return  <code>null</code>
     */
    public T get() {
        return null;
    }

    /**
     * Creates a new phantom reference that refers to the given object and
     * is registered with the given queue.
     *
     * <p> It is possible to create a phantom reference with a <tt>null</tt>
     * queue, but such a reference is completely useless: Its <tt>get</tt>
     * method will always return null and, since it does not have a queue, it
     * will never be enqueued.
     *
     * @param referent the object the new phantom reference will refer to
     * @param q the queue with which the reference is to be registered,
     *          or <tt>null</tt> if registration is not required
     */
    public PhantomReference(T referent, ReferenceQueue<? super T> q) {
        super(referent, q);
    }

}
```

不过可以用这个传入的队列来监测对象是否被回收。



# 类与类加载

## 类文件信息

Class文件采用了类似于C中结构体的伪结构来存储数据。

```
Classfile /Users/nagocoler/Develop.localized/JavaHelloWorld/target/classes/com/test/Main.class
  Last modified 2022-2-23; size 444 bytes
  MD5 checksum 8af3e63f57bcb5e3d0eec4b0468de35b
  Compiled from "Main.java"
public class com.test.Main
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #3.#21         // java/lang/Object."<init>":()V
   #2 = Class              #22            // com/test/Main
   #3 = Class              #23            // java/lang/Object
   #4 = Utf8               <init>
   #5 = Utf8               ()V
   #6 = Utf8               Code
   #7 = Utf8               LineNumberTable
   #8 = Utf8               LocalVariableTable
   #9 = Utf8               this
  #10 = Utf8               Lcom/test/Main;
  #11 = Utf8               main
  #12 = Utf8               ([Ljava/lang/String;)V
  #13 = Utf8               args
  #14 = Utf8               [Ljava/lang/String;
  #15 = Utf8               i
  #16 = Utf8               I
  #17 = Utf8               a
  #18 = Utf8               b
  #19 = Utf8               SourceFile
  #20 = Utf8               Main.java
  #21 = NameAndType        #4:#5          // "<init>":()V
  #22 = Utf8               com/test/Main
  #23 = Utf8               java/lang/Object
{
  public com.test.Main();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 11: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   Lcom/test/Main;

  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=1, locals=4, args_size=1
         0: bipush        10
         2: istore_1
         3: iload_1
         4: iinc          1, 1
         7: istore_2
         8: iinc          1, 1
        11: iload_1
        12: istore_3
        13: return
      LineNumberTable:
        line 13: 0
        line 14: 3
        line 15: 8
        line 16: 13
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      14     0  args   [Ljava/lang/String;
            3      11     1     i   I
            8       6     2     a   I
           13       1     3     b   I
}
SourceFile: "Main.java"
```

在该结构体中，有两种数据类型：无符号数和表

* 无符号数用u1,u2, u4, u8表示1-8个字节的无符号数。可以表示数字，索引引用，数量值，或是UTF-8的字符串。
* 表包含多个无符号数，且以"_info"结尾。

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24egy1gznjcb9bipj21ro0iutfs.jpg&sign=f64c5847c7f766fbfd038f076eca7a13538babaa63a4997bc0e05ca54e0dd2d3)

前四个字节组成了魔数，标志这个文件为JVM可以运行的文件。

下面4个字节为字节码的版本号，前两个字节为次要版本号（已弃用），后两个字节为主要版本号。（51为JDK7， 52为JDK8，依此类推）

紧接着，就是类的常量池了，这里面存放了类中所有的常量信息。最开始的位置存放常量池数量。

随后为常量池中的数据，每一项常量池里面的数据都是一个表。

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24egy1gznkh0jr31j21800u07dm.jpg&sign=e902829718daab83d547c25cf03327c4fe9c0f7f37a0db2feb1a96dc8560e60c)

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24egy1gznkh14d4rj21b805wt9v.jpg&sign=e0b9ab3a79ad43b364c2fe156362b3d3021c7e8e100056ef4908141d95673769)

u1 tag 用于表示当前常量的类型。

| 类型                      | 标志 | 描述                                                         |
| ------------------------- | ---- | ------------------------------------------------------------ |
| CONSTANT_Utf8_info        | 1    | UTF-8编码格式的字符串                                        |
| CONSTANT_Integer_info     | 3    | 整形字面量（第一章我们演示的很大的数字，实际上就是以字面量存储在常量池中的） |
| CONSTANT_Class_info       | 7    | 类或接口的符号引用                                           |
| CONSTANT_String_info      | 8    | 字符串类型的字面量                                           |
| CONSTANT_Fieldref_info    | 9    | 字段的符号引用                                               |
| CONSTANT_Methodref_info   | 10   | 方法的符号引用                                               |
| CONSTANT_MethodType_info  | 16   | 方法类型                                                     |
| CONSTANT_NameAndType_info | 12   | 字段或方法的部分符号引用                                     |

| 常量                    | 项目  | 类型 | 描述                                                |
| ----------------------- | ----- | ---- | --------------------------------------------------- |
| CONSTANT_Methodref_info | tag   | u1   | 值为10                                              |
|                         | index | u2   | 指向声明方法的类描述父CONSTANT_Class_info索引项     |
|                         | index | u2   | 指向名称及类型描述符CONSTANT_NameAndType_info索引项 |

比如我们刚刚的例子中：



![img](https://tva1.sinaimg.cn/large/e6c9d24ely1gznnkpf7cqj21b40503zi.jpg)



可以看到，第一个索引项指向了第3号常量，我们来看看三号常量：



![img](https://tva1.sinaimg.cn/large/e6c9d24ely1gznnmsuh1pj219w03amxj.jpg)

| 常量                | 项目  | 类型 | 描述                     |
| ------------------- | ----- | ---- | ------------------------ |
| CONSTANT_Class_info | tag   | u1   | 值为7                    |
|                     | index | u2   | 指向全限定名常量项的索引 |

那么我们接着来看23号常量又写的啥：



![img](https://tva1.sinaimg.cn/large/e6c9d24ely1gznnqfknqaj21fo0j6te5.jpg)

可以看到指向的UTF-8字符串值为`java/lang/Object`这下搞明白了，首先这个方法是由Object类定义的，那么接着我们来看第二项u2 `name_and_type_index`，指向了21号常量，也就是字段或方法的部分符号引用：

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gzno0zakf9j21eg0qyqbl.jpg&sign=4f34ac113f7c7f929ede364d235dfa0bd6d00387a80f1740a31635bfa94f3a85)

| 常量                      | 项目  | 类型 | 描述                             |
| ------------------------- | ----- | ---- | -------------------------------- |
| CONSTANT_NameAndType_info | tag   | u1   | 值为12                           |
|                           | index | u2   | 指向字段或方法名称常量项的索引   |
|                           | index | u2   | 指向字段或方法描述符常量项的索引 |

其中第一个索引就是方法的名称，而第二个就是方法的描述符，描述符明确了方法的参数以及返回值类型，我们分别来看看4号和5号常量：



![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gzno0z1yp1j21eg0qyqbl.jpg&sign=02f75078d833d8b468a4b07ef537ba3854bb99bb6e76f489e831d101fa0f14b1)

可以看到，方法名称为""，一般构造方法的名称都是，普通方法名称是什么就是什么，方法描述符为"()V"，表示此方法没有任何参数，并且返回值类型为void，描述符对照表如下：

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gzno2stssaj216i08mjsr.jpg&sign=9de3447ab30ed49791e62378f3738337e37f352ec92bad07280e439a2f4a01bf)

在常量池之后，紧接着为访问标志。

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gznos6c7j9j21e60giq7s.jpg&sign=2372c1160e8d2416ff42910374cbab25eac36403ad5fdc95d09463cd3e24bd0c)

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gznp9glonej216i0hcjui.jpg&sign=3478afd563b894243e7957bedd3a815e6b2ae7bfa2a456e1fbc8c9e0b05a94bb)

再往下就是类索引、父类索引、接口索引：



![img](https://tva1.sinaimg.cn/large/e6c9d24ely1gznp3uofdej219803q0t7.jpg)

可以看到它们的值也是指向常量池中的值，其中2号常量正是存储的当前类信息，3号常量存储的是父类信息，这里就不再倒推回去了，由于没有接口，所以这里接口数量为0，如果不为0还会有一个索引表来引用接口。



接着就是字段和方法表集合了：



![img](https://tva1.sinaimg.cn/large/e6c9d24ely1gznp8gd1nfj21ai04mdgp.jpg)

如下代码:

```java
public class Main{
    public static int a = 10;
    
    public staic void main(String...args){
        int i = 10;
        int a = i++;
        int b = ++i;
    }
}
```

现在字节码就新增了一个字段表，这个字段表实际上就是我们刚刚添加的成员字段`a`的数据。



可以看到一共有四个2字节的数据：



![img](https://tva1.sinaimg.cn/large/e6c9d24ely1gznpcxjzgfj216o06et9o.jpg)

第二个数据name_index表示字段的名称常量。

descriptor_index存放描述符， 这里是I

最后，`attrbutes_count`属性计数器，用于描述一些额外信息，这里我们暂时不做介绍。

接着就是我们的方法表了：



![img](https://tva1.sinaimg.cn/large/e6c9d24ely1gznppnxpcqj21ai04odgx.jpg)

可以看到方法表中一共有三个方法，其中第一个方法我们刚刚已经介绍过了，它的方法名称为`<init>`，表示它是一个构造方法，我们看到最后一个方法名称为`<clinit>`，这个是类在初始化时会调用的方法（是隐式的，自动生成的），它主要是用于静态变量初始化语句和静态块的执行，因为我们这里给静态成员变量a赋值为10，所以会在一开始为其赋值：

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gznpt5dhg3j224c0katcg.jpg&sign=e4c6df0bf796fc569946f873135f354cd90e9bbf1a2a6835c9604c103c1fa29f)

而第二个方法，就是我们的`main`方法了，但是现在我们先不急着去看它的详细实现过程，我们来看看它的属性表。



属性表实际上类中、字段中、方法中都可以携带自己的属性表，属性表存放的正是我们的代码、本地变量等数据，比如main方法就存在4个本地变量，那么它的本地变量存放在哪里呢：



![img](https://tva1.sinaimg.cn/large/e6c9d24ely1gznpy0i9ehj21by0hywii.jpg)

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gznq0wqe4xj215a0bi76l.jpg&sign=6ad39b8909cd5b5e788652f812a7d98697c10e579d9e43483bced35d3bbef998)

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gznq26f7rhj219w0ekq5v.jpg&sign=49100060018dade682b6184295afb9be810cb033a47547859264a142723d0ee8)

最后，类也有一些属性：

![img](https://tva1.sinaimg.cn/large/e6c9d24ely1gznq712n66j21dw0n20xw.jpg)

此属性记录的是源文件名称。

## 字节码指令

```java
public static void main(String...args){
    int i = 10;
    int a = i++:
    int b = ++i;
}
```

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gznqsryzgfj225c0lgq6o.jpg&sign=6b2da138a32cc5025d3997bfcb651fa68de3a8f74a854951952a4c2630c71f75)

1. bipush， 将10推至栈顶
2. 将栈顶数值存入1号本地变量，即变量i中
3. 将i中的值推至栈顶
4. 使用iinc指令，将1号变量值增加1
5. 将操作栈顶的数存入2号变量，即a
6. 将1号变量的值增加1.
7. 将1号变量值推向栈顶
8. 将栈顶值存入3号变量

## ASM 字节码编程

创建一个简单的Main类方式如下：

```java
public class Main{
    public static void main(String...args){
        ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
    }
}
```

获取ClassWriter对象， 构造时传参：

* 0， 不会自动计算操作数栈和临时变量表，需要自己指定。
* ClassWriter.COMPUTE_MAXS(1)， 这种方式会自动计算操作数栈和局部临时变量表。
* ClassWriter.COMPUTE_FRAMES 这种方式还会自动计算StackMapFrames

```java
public class Main{
	public static void main(String[] args) {
		ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
		writer.visit(V11, ACC_PUBLIC, "com/test/Main", null, "java/lang/Object", null);
		writer.visitEnd();

		try(var stream = new FileOutputStream("./Main.class")){
			stream.write(writer.toByteArray());
		}catch (IOException e){
			e.printStackTrace();
		}
	}

}
```

反编译结果：

```java
package com.test;

public class Main {
}
```

正常的类默认会有一个无参构造的， 添加无参构造：

```java
public class Main{
	public static void main(String[] args) {
		ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
		writer.visit(V11, ACC_PUBLIC, "com/test/Main", null, "java/lang/Object", null);
        writer.visitMethod(ACC_PUBLIC, "<init>", "()V", null, null);
        writer.visitEnd();

		try(var stream = new FileOutputStream("./Main.class")){
			stream.write(writer.toByteArray());
		}catch (IOException e){
			e.printStackTrace();
		}
	}

}		
```

但是这个构造方法还没有添加父类构造调用

```
public com.test.Main();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 11: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   Lcom/test/Main;
```

```java
public class Main{
	public static void main(String[] args) {
		ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
		writer.visit(V11, ACC_PUBLIC, "com/test/Main", null, "java/lang/Object", null);
		var visitor = writer.visitMethod(ACC_PUBLIC, "<init>", "()V", null, null);
		visitor.visitCode();

		var l1 = new Label();
		visitor.visitLabel(l1);
		visitor.visitLineNumber(11, l1);

		visitor.visitVarInsn(ALOAD, 0);
		visitor.visitMethodInsn(INVOKESPECIAL, "java/lang/Object", "<init>", "()V", false);
		visitor.visitInsn(RETURN);
		var l2 = new Label();
		visitor.visitLabel(l2);
		//添加本地变量表
		visitor.visitLocalVariable("this", "Lcom/test/Main;", null, l1, l2, 0);
		//设置最大栈深度和本地变量数
		visitor.visitMaxs(1, 1);
		//结束编辑
		visitor.visitEnd();
		writer.visitEnd();

		try(var stream = new FileOutputStream("./Main.class")){
			stream.write(writer.toByteArray());
		}catch (IOException e){
			e.printStackTrace();
		}
	}

}
```

接下来添加main方法。

```java
public static void main(String[] args) {
    int a = 10;
    System.out.println(a);
}
```

```java
//开始安排main方法
MethodVisitor v2 = writer.visitMethod(ACC_PUBLIC | ACC_STATIC, "main", "([Ljava/lang/String;)V", null, null);
v2.visitCode();
//记录起始行信息
Label l3 = new Label();
v2.visitLabel(l3);
v2.visitLineNumber(13, l3);

//首先是int a = 10的操作，执行指令依次为：
// bipush 10     将10推向操作数栈顶
// istore_1      将操作数栈顶元素保存到1号本地变量a中
v2.visitIntInsn(BIPUSH, 10);
v2.visitVarInsn(ISTORE, 1);
Label l4 = new Label();
v2.visitLabel(l4);
//记录一下行信息
v2.visitLineNumber(14, l4);

//这里是获取System类中的out静态变量（PrintStream接口），用于打印
v2.visitFieldInsn(GETSTATIC, "java/lang/System", "out", "Ljava/io/PrintStream;");
//把a的值取出来
v2.visitVarInsn(ILOAD, 1);
//调用接口中的抽象方法println
v2.visitMethodInsn(INVOKEVIRTUAL, "java/io/PrintStream", "println", "(I)V", false);

//再次记录行信息
Label l6 = new Label();
v2.visitLabel(l6);
v2.visitLineNumber(15, l6);

v2.visitInsn(RETURN);
Label l7 = new Label();
v2.visitLabel(l7);

//最后是本地变量表中的各个变量
v2.visitLocalVariable("args", "[Ljava/lang/String;", null, l3, l7, 0);
v2.visitLocalVariable("a", "I", null, l4, l7, 1);
v2.visitMaxs(1, 2);
//终于OK了
v2.visitEnd();
```

## 类加载机制

### 类加载过程

所以，一般在这些情况下，如果类没有被加载，那么会被自动加载：



- 使用new关键字创建对象时

- 使用某个类的静态成员（包括方法和字段）的时候（当然，final类型的静态字段有可能在编译的时候被放到了当前类的常量池中，这种情况下是不会触发自动加载的）

- 使用反射对类信息进行获取的时候（之前的数据库驱动就是这样的）

- 加载一个类的子类时

- 加载接口的实现类，且接口带有`default`的方法默认实现时

```java
public class Main {
    public static void main(String[] args) {
        System.out.println(Test.str);
    }

    public static class Test{
        static {
            System.out.println("我被初始化了！");
        }

        public static String str = "都看到这里了，不给个三连+关注吗？";
    }
}
```

但是对于以下情况：

```java
public class Main {
    public static void main(String[] args) {
        System.out.println(Test.str);
    }

    public static class Test{
        static {
            System.out.println("我被初始化了！");
        }

        public final static String str = "都看到这里了，不给个三连+关注吗？";
    }
}
```

Main编译后的字节码：

<img src="https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gzoizzv7azj227c0lcjvp.jpg&sign=9c5d2aeee4e6df668c3c0cefe182aa1f3336016308d866ec52d2ac9d2f1b5951" alt="img" style="zoom:150%;" />



这里ldc指令从常量池将字符串取出并推向操作数栈顶。这个编译器优化导致Test类并没有被初始化。



![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gzojblu4woj21380jkjtf.jpg&sign=b3c8bc3b3bcf503cd21b25a46ddcccdd64e94b1772e0ae429000616caa23f52e)

加载阶段从网络或本地读取一个类文件。

校验阶段会进行文件格式的验证等

- 是否魔数为CAFEBABE开头。

- 主、次版本号是否可以由当前Java虚拟机运行

- Class文件各个部分的完整性如何。

- ...

接下来就是准备阶段了，这个阶段会为类变量分配内存，并为一些字段设定初始值，注意是系统规定的初始值，不是我们手动指定的初始值。

解析阶段，此阶段是将常量池内的符号引用替换为直接引用的过程，也就是说，到这个时候，所有引用变量的指向都是已经切切实实地指向了内存中的对象了。

最后就是真正的初始化阶段了，从这里开始，类中的Java代码部分，才会开始执行，还记得我们之前介绍的`<clinit>`方法吗，它就是在这个时候执行的，比如我们的类中存在一个静态成员变量，并且赋值为10，或是存在一个静态代码块，那么就会自动生成一个`<clinit>`方法来进行赋值操作，但是这个方法是自动生成的。



## 类加载器

我们可以自定义类加载器，也可以使用官方自带的类加载器去加载类。对于任意一个类，都必须由加载它的类加载器和这个类本身一起共同确立其在Java虚拟机中的唯一性。

一个类可以由不同加载器加载，同时，不同加载器加载出的同一个类其实并不会是同一个类。

```java
public class Main {
    public static void main(String[] args) throws ReflectiveOperationException {
        Class<?> testClass1 = Main.class.getClassLoader().loadClass("com.test.Test");
        CustomClassLoader customClassLoader = new CustomClassLoader();
        Class<?> testClass2 = customClassLoader.loadClass("com.test.Test");

     	  //看看两个类的类加载器是不是同一个
        System.out.println(testClass1.getClassLoader());
        System.out.println(testClass2.getClassLoader());
				
      	//看看两个类是不是长得一模一样
        System.out.println(testClass1);
        System.out.println(testClass2);

      	//两个类是同一个吗？
        System.out.println(testClass1 == testClass2);
      
      	//能成功实现类型转换吗？
        Test test = (Test) testClass2.newInstance();
    }

    static class CustomClassLoader extends ClassLoader {
        @Override
        public Class<?> loadClass(String name) throws ClassNotFoundException {
            try (FileInputStream stream = new FileInputStream("./target/classes/"+name.replace(".", "/")+".class")){
                byte[] data = new byte[stream.available()];
                stream.read(data);
                if(data.length == 0) return super.loadClass(name);
                return defineClass(name, data, 0, data.length);
            } catch (IOException e) {
                return super.loadClass(name);
            }
        }
    }
}
```

通过结果我们发现，即使两个类是同一个Class文件加载的，只要类加载器不同，那么这两个类就是不同的两个类。

JDK内部提供的加载器一共有三个，上面的Main类是被AppClassLoader加载的, JDK内部的类由BootstrapClassLoader加载，实际上是为了实现双亲委派机制而做的。

![img](https://www.yuque.com/api/filetransfer/images?url=https%3A%2F%2Ftva1.sinaimg.cn%2Flarge%2Fe6c9d24ely1gzpoy41z31j20wb0u040w.jpg&sign=6c69a071960414ff49e314822fcc442e4240a0f82ff839c0250c3fff9c636ac2)
