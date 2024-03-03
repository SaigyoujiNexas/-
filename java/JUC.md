# 多线程

由于每个进程都有各自的内存空间， 每个进程相互隔离， 互不干扰， 进程间通信就变得麻烦。

而线程共享内存地址，运行空间。

Java5时， 添加了`java.util.concurrent`(JUC)包， 支持了更好的多任务

## 并发和并行

### 顺序执行

说白了， 依次执行任务

![image-20220926235346380](https://s2.loli.net/2022/09/26/4zfEICO16WaiHKv.png)

### 并发执行

并发执行是通过时间片轮转算法，在宏观上多个任务同时进行

![image-20220926235228770](https://s2.loli.net/2022/09/26/H8N4jBDGiy5WPdv.png)

Java线程采用了该机制。

### 并行执行

可以同一时间做多个任务。

![image-20220926235520247](https://s2.loli.net/2022/09/26/dVU8mMGkaZWQrOl.png)

分布式计算模型采用了MapReduce。

## 锁机制

sychronized一定是和某个对象相关联的

```java
public static void main(String[] args){
    synchronized(Main.class){
        
    }
}
```

查看字节码

```java
0 ldc #7 <com/bennyhuo/retrofit/tutorials/sample/Main>
 2 dup
 3 astore_1
 4 monitorenter
 5 aload_1
 6 monitorexit
 7 goto 15 (+8)
10 astore_2
11 aload_1
12 monitorexit
13 aload_2
14 athrow
15 return

```

`monitorenter`和`monitorexit`分别对应上锁和释放锁， 每个对象有一个monitor监视器， 一代monitor所有权被某个线程持有， 那么其他线程无法获得（管程模型）

第12行的exit其实是出现异常时的锁释放，athrow抛出异常

![image-20220930005519772](https://s2.loli.net/2022/09/30/XSIpZLtAqcE8zdy.png)

实际上synchronized的锁是存储在Java对象头中的， 对象头信息中，**Mark Word**用于存放`hashCode`和`锁信息`

![image-20220930005643782](https://s2.loli.net/2022/09/30/zphWua6i7eVyqS5.png)

### 重量级锁

JDk6之前，synchronized也称之为重量级锁，monitor依赖于底层Lock实现， Java的线程是映射到操作系统原生线程上，切换成本较高。

每个对象都有一个monitor与之关联， `HotSpot`虚拟机中， monitor由ObjectMonitor实现：

```cpp
ObjectMonitor(){
    _header			= NULL;
    _count 			= 0;
    _waiter			= 0;
    _recursions		= 0;
    _object 		= NULL;
    _owner			= NULL;
    _WaitSet		= NULL;//wait线程集合
    _WaitSetLock	= 0;
    _Responsible	= NULL;
    _succ			= NULL;
    _cxq			= NULL;
    FreeNext		= NULL;
    _ExtryList		= NULL; //处于等待锁block状态的线程集合
    _SpinFreq		= 0;
    _SpinClock		= 0;
    OwnerIsThread	= 0;
    
}
```

每个等待锁的线程被封装成`ObjectWaiter`对象。

![image-20220930230353561](https://s2.loli.net/2022/09/30/JbhYEsZFeBXKDwH.png)

这样的设计思路，在大多数应用上，每一个线程占用同步代码块的时间并不是很长，其实没有必要把一个线程挂起再唤醒。

JDK1.4.2引入了自旋锁，JDK6之后默认开启， 通过无限循环的方式，不断检测是否能够获得锁， 通常自旋锁的循环次数是十次，超过十次采用重量级锁机制。JDK6之后自选次数变为自适应变化的。

![image-20220930231106723](https://s2.loli.net/2022/09/30/Y1CgkJB2LSvn84m.png)

### 轻量级锁

运作机制如下：即将开始执行同步代码块的内容时，首先检查对象的`Mark Word`，查看锁对象是否被其他线程占用，如果无占用，则在当前线程栈桢中建立一个锁记录(Lock Record)空间， 用于复制并存储对象目前的Mark Word信息（Displaced Mark Word）。

 接下来虚拟机使用CAS操作将对象的`Mark Word`更新为轻量级锁状态。

如果CAS失败，说明这是有线程进入这个同步代码块，这时虚拟机再次检查对象的Mark Word是否指向当前线程的栈帧， 如果是， 则当前线程拥有了该对象的锁，否则，被其他线程占用，只能将锁膨胀为重量级锁.

![image-20220930232254277](https://s2.loli.net/2022/09/30/jok265ZK8O9GWwC.png)

### 偏向锁

偏向锁当某个线程第一次获得锁时， 说明接下来都没有其他线程获取此锁，那么持有锁的线程将不再需要同步操作。

通过添加`-XX:+UseBiased`来开启偏向锁。

如果对象调用`hashCode()`方法，那么该对象就不支持偏向锁，转而进入轻量级锁状态。如果对象在偏向锁状态，再去调用hashCode方法，则直接升级为重量级锁， 并将哈希值放在`monitor`中。

![image-20220930233014596](https://s2.loli.net/2022/09/30/a4mNtIKn7zAV9fx.png)

### 锁消除和锁粗化

当运行时根本不可能出现线程的竞争， 则直接对消除锁的存在。

若一段代码中频繁出现互斥同步现象(循环内部加锁)则会将整个同步范围扩展。

# JMM 内存模型

* 所有的可能产生竞争变量全部存储在主内存

* 每个线程有自己的工作内存
* 不同线程工作内存相互隔离

其中：

* 主内存： 堆中存放对象实例的部分
* 工作内存： 虚拟机栈的部分区域，可能会进行优化放入缓存中。

## 重排序

重排序有以下两种重排序：

* 编译器重排序： 根据优化规则对代码指令重排序
* 机器指令级别重排序：自主判断和变更机器指令的重排序

```java
public class Main{
    private static int a  = 0;
    private static int b = 0;
    public static void main(String ...args){
        new Thread(() -> {
            if(b == 1){
                if(a == 0){
                    System.out.println('A');
                }else{
                    System.out.println('B');
                }
            }
        }).start();
        new Thread(() -> {
            b = 1;
            a = 1;
        }).start();
    }
}
```

如果对线程2进行重排序，则线程1的判断顺序就会出现问题。

## volatile关键字

如果多线程访问同一个变量， 则这个变量会被拷贝到自己线程的工作内存中进行。

```java
public class Main{
    private static int a  = 0;
    public static void main(String...args){
        new Thread(() -> {
            while(a == 0);
            System.out.println("线程结束！");
        }).start();
        Thread.sleep(1000);
        System.out.println("changing value of a....");
        a = 1;
    }
}
```

volatile 指令表示可能有代理修改值，禁止编译器优化，让所有访问者使用同一个内存空间，而不是访问高速缓存，避免代理修改所在地址的值。在JVM中，通过施加内存屏障实现。

## happens-before原则

* 程序次序规则： 保证指令重排对结果无影响
* 监视器锁规则： 对一个锁的解锁解锁后， 其他线程都能看见修改后的结果
* volatile变量结果规则：如果一个线程写volatile变量，其他线程可以读到改变后的结果
* 线程启动规则： 线程A启动线程B， 线程B可以看到B启动之前的结果
* 线程加入规则： 如果线程A join 线程B， 线程B中的任意操作happens-before线程A join 成功返回
* 传递性规则： 如果 A happens-before B, B happens-before  C, 则 A happens-before C

```java
public class Main{
    private static int a = 0;
    private static int b = 0;
    public static void main(String...args){
        a = 10;
        b = a + 1;
        new Thread(() -> {
            if(b > 10) System.out.println(a);
        }).start();
    }
}
```

# 锁框架

## Lock和Condition框架

```java
public interface Lock{
    void lock();
    void lockInterruptibly() throws InterruptedException;
    void tryLock();
    boolean tryLock(longtime, TimeUnit unit) throws InterruptedException;
    void unlock();
    Condition newCondition();
    
}
```

```java
public class Main{
    private static int i  = 0;
    public static void main(String...args){
        Lock testLock = new ReentrantLock();
        Runnable action = () -> {
            for(int j = 0; j < 100000; j++){
                testLock.lock();
                i++;
                testLock.unlock();
            }
        };
        new Thread(action).start();
        new Thread(action).start();
        Thread.sleep(1000);
        System.out.println(i);
    }
}
```

使用wait操作, 需要使用Condition对象，如下：

```java
public interface Condition{
    void await();
    
    void awaitUninterruptibly();
    long awaitNanos(long nanosTimeout);
    boolean await(long time, TimeUnit unit);
    boolean awaitUntil(Date deadline);
    void signal();
    void signalAll();
}
```

```java
public class Main{
    private static int i  = 0;
    public static void main(String...args){
        Lock testLock = new ReentrantLock();
        Condition condition = testLock.newCondition();
        new Thread(() -> {
            testLock.lock();
            try{
                condition.await();
            }catch(Throwable e){
                e.printStackTrace();
            }
            testLock.unlock();
        }).start();
        Thread.sleep(1000);
        new Thread(() -> {
            testLock.lock();
            condition.signal();
            testLock.unlock();
        }).start();
    }
}
```

## 可重入锁

`ReentrantLock`是一种可以重复上锁的锁.
在当前线程持有锁的情况下加锁不会阻塞，但必须释放相同数量的锁，其他线程才能从等待队列移除

```java
public class Main{
    public static void main(String...args){
        ReentrantLock lock = new ReentrantLock();
        lock.lock();
        var t1 = new Thread(lock::lock), t2 = new Thread(lock::lock);
        t1.start(); t2.start();
        TimeUnit.SECONDS.sleep(1);
        System.out.println("thread numbers of waiting lock release" + lock.getQueueLength());
        System.out.println("whether thread 1 is in waiting queue " + lock.hasQueuedThread(t1));
        System.out.println("whether thread 2 is in waiting queue " + lock.hasQueuedThread(t2));
        System.out.println("whether current thread is in waiting queue " + lock.hasQueuedThread(Thread.currentThreaed()));
        
    }
}
```

## 读写锁

```java
public interface ReadWriteLock{
    //it let multiple thread can obtain the read lock when no thread  occupy the write lock.
    Lock readLock();
    //it let only one thread can obtain the write lock when no thread occupy the read lock.
    Lock writeLock();
}
```

该接口默认实现类为`ReentrantReadWriteLock` 

```java
public class Main{
    public static void main(String ...args){
        ReentrantReadWriteLock lock = new ReentrantReadWriteLock();
        lock.writeLock.lock();
        lock.writeLock.lock();
        new Thread(() -> {
            lock.writeLock.lock();
            System.out.println("obtain the write lock successfully!");
        }).start();
        lock.writeLock().unlock();
        System.out.println("Release first read lock successfully!");
        lock.writeLock().unlock();
        System.out.println("Release second read lock successfully!");
    }
}

```

## 锁降级和锁升级

当一个线程持有写锁， 但是这个线程却可以获取读锁（反之不行）

* 写 -> 读: 锁降级
* 读 -> 写：锁升级 （不支持）

```java
public static void main(String...args){
    ReentrantReadWriteLock lock = new ReentrantReadWriteLock();
    lock.writeLock().lock();
    lock.readLock().lock();
    new Thread(() -> {
       System.out.println("Start obtain read lock");
        lock.readLock().lock();
        System.out.println("read lock obtained");
    }).start();
    TimeUnit.SECONDS.sleep(1);
    lock.writeLock().unlock();
}
```

锁降级：在有写锁的情况下在申请读锁然后释放写锁，这种过程称之为锁降级。

锁升级：就是反着来呗

## 队列同步器AQS

`ReentrantLock`的`lock()`和`unlock()`都交给了`sync.lock()`与`sync.release()`

## 底层实现

`AbstractQueuedSynchronizer`是实现锁机制的基础.

![image-20221124210439472](https://s2.loli.net/2022/11/24/JLjvugwYRfSpiW6.png)

AQS中有一个head和一个tail分别记录双向链表的头和尾，其之后的一系列操作围绕改队列进行。

```java
abstract static class Node {
        volatile Node prev;       // initially attached via casTail
        volatile Node next;       // visibly nonnull when signallable
        Thread waiter;            // visibly nonnull when enqueued
        volatile int status;      // written by owner, atomic bit ops by others

        // methods for atomic operations
        final boolean casPrev(Node c, Node v) {  // for cleanQueue
            return U.weakCompareAndSetReference(this, PREV, c, v);
        }
        final boolean casNext(Node c, Node v) {  // for cleanQueue
            return U.weakCompareAndSetReference(this, NEXT, c, v);
        }
        final int getAndUnsetStatus(int v) {     // for signalling
            return U.getAndBitwiseAndInt(this, STATUS, ~v);
        }
        final void setPrevRelaxed(Node p) {      // for off-queue assignment
            U.putReference(this, PREV, p);
        }
        final void setStatusRelaxed(int s) {     // for off-queue assignment
            U.putInt(this, STATUS, s);
        }
        final void clearStatus() {               // for reducing unneeded signals
            U.putIntOpaque(this, STATUS, 0);
        }

        private static final long STATUS
            = U.objectFieldOffset(Node.class, "status");
        private static final long NEXT
            = U.objectFieldOffset(Node.class, "next");
        private static final long PREV
            = U.objectFieldOffset(Node.class, "prev");
    }
```

一开始head和tail都是null

```java
    /**
     * Head of the wait queue, lazily initialized.
     */
    private transient volatile Node head;

    /**
     * Tail of the wait queue. After initialization, modified only via casTail.
     */
    private transient volatile Node tail;

    /**
     * The synchronization state.
     */
    private volatile int state;
```

当没有线程占用时，state为0

底层使用unsafe

```java
private static final Unsafe U = Unsafe.getUnsafe();
    private static final long STATE
        = U.objectFieldOffset(AbstractQueuedSynchronizer.class, "state");
    private static final long HEAD
        = U.objectFieldOffset(AbstractQueuedSynchronizer.class, "head");
    private static final long TAIL
        = U.objectFieldOffset(AbstractQueuedSynchronizer.class, "tail");

    static {
        Class<?> ensureLoaded = LockSupport.class;
    }
```

内部使用了CAS算法，直接修改内存空间。

AQS提供了一些可重写方法

```java
//独占式获取同步状态， 查看同步状态是否和参数一致，如果没有问题，那么使用CAS操作设置同步状态并返回true
protected boolean tryAcquire(int arg){
    throw new UnsupportedOperationException();
}
//独占式释放同步状态
protected boolean tryRelease(int arg){
    throw new UnsupportedOperationException();
}
//共享式获取同步状态，返回值大于0表示成功
protected int tryAcquireShared(int arg){
    throw new UnsupportedOperationException();
}
//共享式释放同步状态
protected boolean tryReleaseShared(int arg){
    throw new UnsupportedOperationException();
}
//是否在独占模式下被当前线程占用
protected boolean isHeldExclusively(){
    throw new UnsupportedOperationException();
}
```

公平锁当中的实现:

```java
static final class FairSync extends Sync {
        private static final long serialVersionUID = -3000897897090466540L;
	public void lock() {
        sync.lock();
    }
```

```java
//Sync.lock
@ReservedStackAccess
final void lock() {
    if (!initialTryLock())
        acquire(1);
}
```

```java
public final void acquire(int arg) {
        if (!tryAcquire(arg))
            acquire(null, arg, false, false, false, 0L);
}

```

先尝试`tryAcquire`如果尝试加独占锁失败，则将其加入等待队列。

```java
final int acquire(Node node, int arg, boolean shared,
                      boolean interruptible, boolean timed, long time) {
        Thread current = Thread.currentThread();
        byte spins = 0, postSpins = 0;   // retries upon unpark of first thread
        boolean interrupted = false, first = false;
        Node pred = null;                // predecessor of node when enqueued
/*
         * 自旋:
         *    检查是否第一次进入方法
         *    如果是确保头部节点稳定,否则需要确保是合法的前驱节点
         *    如果第一次进来或者节点没有入队列，尝试获取锁
         *    如果节点没有创建，则创建
         *    如果节点没有入队列，则首次尝试入队列 
         *    如果线程从park中被唤醒，再次自旋重试
         *    如果节点没有获取到锁且状态不是waiting，则设置为waiting
         *    都不满足则阻塞线程，线程被唤醒后清空waiting 状态，检查是否取消了等待 
         */


        for (;;) {
            //第一次进来不会执行
            if (!first && (pred = (node == null) ? null : node.prev) != null &&
                !(first = (head == pred))) {
                if (pred.status < 0) {
                    cleanQueue();           // predecessor cancelled
                    continue;
                } else if (pred.prev == null) {
                    Thread.onSpinWait();    // ensure serialization
                    continue;
                }
            }
            //当前节点的前一个节点是否为头节点或为空，即没有入队列
            if (first || pred == null) {
                boolean acquired;
                try {
                    if (shared)
                        acquired = (tryAcquireShared(arg) >= 0);
                    else
                        acquired = tryAcquire(arg);
                } catch (Throwable ex) {
                    cancelAcquire(node, interrupted, false);
                    throw ex;
                }
                //获取到了锁
                if (acquired) {
                    if (first) {			//头节点即为占位节点
                        node.prev = null;
                        head = node;
                        pred.next = null;
                        node.waiter = null;
                        if (shared)
                            signalNextIfShared(node);
                        if (interrupted)
                            current.interrupt();
                    }
                    return 1;
                }
            }
            if (node == null) {                 // 生成node
                if (shared)
                    node = new SharedNode();
                else
                    node = new ExclusiveNode();
            } else if (pred == null) {          // try to enqueue
                node.waiter = current;
                Node t = tail;
                node.setPrevRelaxed(t);         // avoid unnecessary fence
                if (t == null)
                    tryInitializeHead();
                else if (!casTail(t, node))
                    node.setPrevRelaxed(null);  // back out
                else
                    t.next = node;
            } else if (first && spins != 0) {
                --spins;                        // reduce unfairness on rewaits
                Thread.onSpinWait();
            } else if (node.status == 0) {
                node.status = WAITING;          // enable signal and recheck
            } else {
                //拿锁失败
                long nanos;
                spins = postSpins = (byte)((postSpins << 1) | 1);
                if (!timed)		//不带超时的park
                    LockSupport.park(this);
                else if ((nanos = time - System.nanoTime()) > 0L)
                    LockSupport.parkNanos(this, nanos);
                else
                    break;
                node.clearStatus();
                if ((interrupted |= Thread.interrupted()) && interruptible)
                    break;
            }
        }
        return cancelAcquire(node, interrupted, interruptible);
    }
```

其中， `LockSupport.park()`实现了对线程的挂起

```java
        var thread = Thread.currentThread();
        new Thread(() -> {
            try {
                TimeUnit.SECONDS.sleep(1);
                System.out.println("Main thread can continue to run");
                LockSupport.unpark(thread);
                //thread.interrupt();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }).start();
        System.out.println("Main thread was suspended");
        LockSupport.park();
		Syste.out.println("Main thread can continue to process");
```

解锁操作:

```java
    public void unlock() {
        sync.release(1);
    }
```

```java
    public final boolean release(int arg) {
        if (tryRelease(arg)) {
            signalNext(head);
            return true;
        }
        return false;
    }
```



