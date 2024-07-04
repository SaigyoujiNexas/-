# 线程

```java
package threads;

/**
 * @author Cay Horstmann
 */

public class ThreadTest 
{
    public static final int DELAY = 10;
    public static final int STEPS = 100;
    public static final double  MAX_AMOUNT = 1000;

    public static void main(String[] args) {
        var bank = new Bank(4, 100000);
        Runnable task1 = () ->{
            try{
                for(int i = 0; i < STEPS; i++)
                {
                    double amount = MAX_AMOUNT * Math.random();
                    bank.transfer(0, 1, amount);
                    Thread.sleep((int)(DELAY * Math.random()));
                }
            }
            catch (InterruptedException e)
            {}
        };
        Runnable task2 = ()->{
            try {
                double amount = MAX_AMOUNT * Math.random();
                bank.transfer(2, 3, amount);
                Thread.sleep((int) (DELAY * Math.random()));
            }
            catch (InterruptedException e)
            {}
        };
        new Thread(task1).start();
        new Thread(task2).start();
    }
}
```

```java
package threads;

import java.util.*;

/**
 * A bank with a number of bank accounts.
 */
public class Bank
{
   private final double[] accounts;

   /**
    * Constructs the bank.
    * @param n the number of accounts
    * @param initialBalance the initial balance for each account
    */
   public Bank(int n, double initialBalance)
   {
      accounts = new double[n];
      Arrays.fill(accounts, initialBalance);
   }

   /**
    * Transfers money from one account to another.
    * @param from the account to transfer from
    * @param to the account to transfer to
    * @param amount the amount to transfer
    */
   public void transfer(int from, int to, double amount)
   {
      if (accounts[from] < amount) return;
      System.out.print(Thread.currentThread());
      accounts[from] -= amount;
      System.out.printf(" %10.2f from %d to %d", amount, from, to);
      accounts[to] += amount;
      System.out.printf(" Total Balance: %10.2f%n", getTotalBalance());
   }

   /**
    * Gets the sum of all account balances.
    * @return the total balance
    */
   public double getTotalBalance()
   {
      double sum = 0;

      for (double a : accounts)
         sum += a;

      return sum;
   }

   /**
    * Gets the number of accounts in the bank.
    * @return the number of accounts
    */
   public int size()
   {
      return accounts.length;
   }
}
```



## 线程状态

* New(新建)
* Runnable（可运行）
* Blocked（阻塞）
* Waiting（等待）
* Timed waiting（计时等待）
* Terminated（终止）

## 新建线程

使用new方法创建后， 该线程的状态是新建（new）， 还没有开始运行

## 可运行线程

调用start方法后， 线程就处于可运行（runnable）状态。

所有的桌面以及服务器操作系统使用抢占式调度，小型设备可能使用协作式调度

## 阻塞和等待线程

当线程处于阻塞或等待状态， 其暂时是不活动的

* 当一个线程试图获取一个内部的对象锁（不是java.util.concurrent库中的Lock）， 而这个锁被其他线程占有， 该线程就会被阻塞。

* 当线程等待另一个线程通知调度器出现一个条件时， 这个线程会进入等待状态。

  调用Object.wait方法或Thread.join方法。或等待java.util.concurrent库中的Lock或Condition时就会出现这种情况

* 有几个有超时参数的方法会让线程进入计时等待（timed waiting）状态， 带有超时参数的方法有Thread.sleep和计时版的Object.wait, Thread.join, Lock.tryLock和Condition.await。



## 终止线程

线程会由于以下两个方法终止：

* run方法正常退出
* 因为一个没有捕获的异常终止了run方法。



# 线程属性

##  中断进程

没有办法强制线程终止。 interrupt方法可以用来请求终止一个线程

当对一个线程调用interrupt方法后， 就会设置线程的中断状态。

若想知道是否设置了中断状态， 调用Thread.currentThread方法获得当前线程， 随后调用isInterrupted方法

```java
while(!Thread.currentThread().isInterrupted && more work to do)
{
    do more work;
}
```

但是如果线程被阻塞， 就无法检查中断状态， 此时引入InterruptedException异常。

被中断的线程可以决定如何项响应中断， 通常线程只希望将中断解释为一个终止请求.

```java
Runnable r = () -> {
    try
    {
        ...
        while(!Thread.currentThread().isInterrupted() && more work to do)
        {
            do some work;
        }
    }
    catch(InterruptedException e)
    {
        // thread was interrupted during sleep or wait
    }
    finally
    {
        cleanup, if required
    }
    // exiting the run method terminates the thread.
}
```

中断状态下调用sleep方法其不会休眠， 其会清除中断状态， 并抛出一个InterruptedException.

当循环调用了sleep， 就不要去检测中断状态， 应当捕获InterruptedException异常

```java
Runnable r = () -> S
{
    try
    {
        ...
        while(more work to do)
        {
            do more work;
            Thread.sleep(delay);
        }
        catch(InterruptedException e)
        {
            // thread was interrupted during sleep
        }
        finally
        {
            cleanup, if required;
        }
        //exiting the run mothod terminatas the thread.
    }
}
```

tips: 不要在底层抑制InterruptedException！， 可以

```java
void mySubTask()
{
    ...
    try{sleep(delay);}
    catch (InterruptedException e) {Thread.currentThread().interrupt();}
}
```

或者干脆 throws 出去

## 守护线程

通过调用

```java
t.setDaemon(true);
```

将一个线程转换为守护线程（daemon thread）。

## 线程名

默认情况下吗， 线程名字 通常为Thread-2之类的， 可以用setName为线程设置任何名字

```java
var t = new Thread(runnable);
t.setName("Web crawler");
```

这在线程转储时非常重要

## 未捕获异常的处理器

线程的run方法不能抛出任何检查型异常， 但是任何非检查型异常都会导致线程终止。

对于可以传播的异常， 没有任何catch语句。

在线程死亡之前， 异常会传递到一个用于处理未捕获异常的处理器

这个处理器必须属于一个实现了Thread.UncaughtExceptionHandler接口的类， 这个接口只有一个方法

```java
void uncaughtException(Thread t, Throwable e)
```

可以用setUncaughtExceptionHandler方法为任何一个线程安装一个处理器。 亦可以用Thread类的静态方法setDefaultUncaughtExceptionHandler方法为所有线程安装一个默认的处理器。

替代处理器可可以使用日志API将未捕获异常的报告发送到一个日志文件。

没有安装处理器下， 默认为null。 但是如果没有给单个线程安装处理器， 那么这个处理器就是该线程的ThreadGroup1对象

ThreadGroup类实现了Thread.UncaughtexceptionHandler接口， 其uncaughtException方法执行以下操作：

1. 若有父线程组， 那么调用父线程组的uncaughtException方法
2. 否则， 若Thread.getDefaultExceptionHandler方法返回非null处理器， 调用该处理器。
3. 否则， 若Throwable是ThreadDeath的一个实例， 什么都不做
4. 否则， 将线程的名字和Throwable的栈轨迹输出到System.err





## 线程优先级



在java程序设计语言中， 每一个线程都有一个优先级， 默认情况下， 一个线程会继承构造它的线程的优先级。

可以调用setPriority方法提高或降低任何一个线程的优先级。 

MIN_PRIORITY (Thread类中定义为1)与MAX_PRIORITY（Thread类中定义为10) 之间的任何值。 NORM_PRIORITY定义为5。

**线程优先级高度依赖于系统** 

windows系统有7个优先级别

LInux系统会忽略优先级

# 同步

若两个线程存取同一个对象， 并且每个线程分别调用一个修改该对象状态的方法。可以预见， 这两个线程会相互覆盖， 取决于线程访问数据的次序， 可能会导致数据被破坏。 这种情况通常称为竟态条件（race condition）

## 竟态条件的一个例子

```java
package unsynch;

import threads.Bank;
/**
 * This program shows corruption when multiple threads access a data structure.
 * @author Cay Horstmann
 */
public class UnsynchBankTest 
{
    public static final int NACCOUNTS = 100;
    public static final double INITIAL_BALANCE = 1000;
    public static final double MAX_AMOUNT = 1000;
    public static final int DELAY = 10;

    public static void main(String[] args) {
        var bank = new Bank(NACCOUNTS, INITIAL_BALANCE);
        for (int i = 0; i < NACCOUNTS; i++)
        {
            int fromAccount = i;
            Runnable r = () ->{
                try{
                    while(true)
                    {
                        int toAccount  = (int)(bank.size() * Math.random());
                        double amount = MAX_AMOUNT * Math.random();
                        bank.transfer(fromAccount, toAccount, amount);
                        Thread.sleep((int)(DELAY * Math.random()));
                    }
                }
                catch(InterruptedException e)
                {
                }
            };
            var t = new Thread(r);
            t.start();
        }
    }    
}
```



当两个线程试图同时更新一个账户时， 会出现总金额减少的问题。

account[to] += amount;

这个操作并非原子操作

1. 将accounts[to] 加载到寄存器
2. 增加amount
3. 将结果写回到accounts[to].

假定第一个线程完成执行步骤1和2随后其运行权被抢占， 第2个线程唤醒， 更新同一个元素， 随后第一个线程被唤醒， 完成其第三步， 然而该操作会抹去第二个线程所做的更新。

此处的关键问题是如何能够确保线程失控之前方法已经运行完成， 那么银行账户的状态就不会被破坏。



## 锁对象

有两种机制可以防止并发访问代码块。

1. 使用synchronized关键字
2. 引入ReentrantLock类。



synchronized关键字自动提供一个锁及相关的“条件”。

java.util.concurrent框架为这些基础机制提供了单独的类。

用ReentrantLock保护代码块的基本结构如下：

```java
myLock.lock();			// a ReentrackLock object
try{
    critical section	
}
finally
{
    myLock.unlock();		//make sure the lock is unlocked even if an exception is throw
}
```

这个结构确保任何时刻只有一个线程进入临界区。 、

一旦 一个线程锁定了锁对象， 其他的任何线程都无法通过lock语句。 当其他线程调用lock时3， 他们会暂停， 直到第一个线程释放这个锁对象。

```java
public class Bank
{
    private var bankLock  = new ReentrantLock();
    ...;
    public void transfer (int from, int to, int amount)
    {
        bankLock.lock();
        try{
            System.out.print(Thread.currentThread());
            accounts[from] -= amount;
            System.out.printf(" %10.2f from %d to %d", amount, from, to);
            accounts[to] += amount;
            System.out.printf("  Total Balance: %10.2f%n", getTotalBalance());
        }
        finally{
            bankLock.unlock();
        }
    }
}
```

每个线程都有自己的ReentrankLock对象， 当两个线程同时访问同一个Bank对象， 那么这个锁可以用来保证串行化访问。

这个锁称为重入（reentrant）锁，因为线程可以反复获得已拥有的锁， 锁有一个持有计数（hold count）来跟踪对lock方法的嵌套使用。线程每一次调用lock后都要使用unlock来释放锁。

由于该特性， 被一个锁保护的代码可以调用另一个使用相同锁的方法。

 ## 条件对象

通常线程进入临界区之后却发现只有满足某个条件后才能执行， 可以使用一个条件对象类管理那些已经获得了一个锁却不能做有用工作的线程。

```java
public void transfer(int from, int to, int amount)
{
    bankLock.lock();
    try
    {
        while(accounts[from] < amount)
        {
            // wait
        }
        //transfer funds
        ...;
    }
    finally{
        bankLock.unlock();
    }
}
```

这种方法使该线程获得了对bankLock的排他性访问权， 因此别的线程没有存款的机会， 这里就要引入条件对象

一个锁对象可以有一个或多个相关联的条件对象， 可以用newCondition方法获得一个条件对象。

```java
class Bank
{
    private Condition sufficientFunds;
    ...;
    public Bank()
    {
        ...
            sufficientFunds = bankLock.newCondition();
    }
}
```



如果transfer方法发现资金不足， 它会调用

```java
sufficientFunds.await();
```

当前线程现在暂停， 并放弃锁。

当另一个线程调用signalAll方法时， 该线程解除暂停。



```java
sufficientFunds.signalAll();
```



```java
package synch;

import java.util.*;
import java.util.concurrent.locks.*;

/**
 * A bank with a number of bank accounts that uses locks for serializing access.
 */
public class Bank 
{
    private final double[] accounts;
    private Lock bankLock;
    private Condition sufficientFunds;
    /**
     * Constructs the bank.
     * @param n the number of accounts
     * @param initialBalance the initial balance for each accounts.
     */
    public Bank(int n, double initialBalance)
    {
        accounts = new double[n];
        Arrays.fill(accounts, initialBalance);
        bankLock = new ReentrantLock();
        sufficientFunds = bankLock.newCondition();
    }

    /**
     * Transfer money from one account to another.
     * @param from the account to transfer from
     * @param to the account to transfer to
     * @param amount the amount to transfer
     */

     public void transfer(int from, int to, double amount) throws  InterruptedException
     {
         bankLock.lock();
         try{
             while(accounts[from] < amount)
             {
                 sufficientFunds.await();
             }
             System.out.print(Thread.currentThread());
             accounts[from] -=  amount;
             System.out.printf(" %10.2f from %d to %d", amount, from, to);
             accounts[to] += amount;
             System.out.printf(" Total Balance: %10.2f%n", getTotalBalance());
             sufficientFunds.signalAll();
            }
            finally{
                bankLock.unlock();
            }
     }
     /**
      * Gets the sum of all account balances.
      *@return the total balance
      */
      public double getTotalBalance()
      {
          bankLock.lock();
          try
          {
              double sum = 0;
              for (double a: accounts)
              {
                  sum += a;
              }
              return sum;
          }
          finally
          {
              bankLock.unlock();
          }
    }
     /**
    * Gets the number of accounts in the bank.
    * @return the number of accounts
    */
        public int size()
        {
            return accounts.length;
        }   
}
```

## synchronized 关键字

* 锁用来保护代码片段， 一次只能有一个线程执行被保护的代码
* 锁可以管理试图进入被保护代码段的线程
* 一个锁可以有一个或多个相关联的条件对象
* 每个条件对象管理那些已经进入被保护代码段但还不能运行的线程。



Lock和Condition接口允许程序员充分控制锁定。

但大多数情况下， 并不需要如此控制。

若一个方法声明是有synchronized关键字， 对象的锁将保护整个方法。

```java
public synchronized void method()
{
    method body;
}
```

内部对象锁只有一个关联条件。

```java
class Bank
{
    private double[] accounts;
    
    public synchronized void transfer(int  from, int to, int amount)
        throws InterruptedException
    {
        while(accounts[from] < amount)
            wait();
        accounts[from] -= amount;
        accounts[to] += amount;
        notifyAll();
    }
    public synchronized double getTotalBalance(){...}
}
```

使用synchronized关键字可以得到更加简单的代码。

将静态方法声明为同步也是合法的。

内部锁和条件存在的一些限制

* 不能中断一个正在尝试获得锁的线程
* 不能指定尝试获得锁时的超时时间
* 每个锁仅有一个条件可能是不够的



相关建议：

* 许多情况下， 最好既不使用synchronized也不使用Lock， 而是使用java.util.concurrent包中的某种机制， 它会处理所有的锁定， 例如阻塞队列
* 如果synchronized关键字适合当前程序， 那么尽量使用





```java
package synch2;

import java.util.*;

/**
 * A bank with a number of bank accounts that uses synchronization primaitives.
 */

public class Bank 
{
    private final double[] accounts;

    /**
     * Constructs the bank
     * @param n the number of accounts;
     * @param initialBalance the initial balance for each account
     */
    public Bank(int n, double initialBalance)
    {
        accounts = new double[n];
        Arrays.fill(accounts, initialBalance);
    }
    /**
     * Transfers money from one account to another.
     * @param from the account to transfer from
     * @param to the account to transfer to
     * @param amount the amount to transfer
     */
    public synchronized void transfer(int from, int to, double amount)
    throws InterruptedException
    {
        while (accounts[from] < amount)
            wait();
        System.out.print(Thread.currentThread());
        accounts[from] -= amount;
        System.out.printf(" %10.2f from %d to %d", amount, from, to);
        accounts[to] += amount;
        System.out.printf(" Total Balance: %10.2f%n", getTotalBalance());
        notifyAll();
    }

    /**
     * Gets the sun of all accounts balances.
     * @return the total balance
     */
    public synchronized double getTotalBalance()
    {
        double sum = 0;
        for (double a : accounts)
            sum += a;
        return sum;
    }
}
```



## 同步块

还有另一种方法获得锁： 进入 一个同步块

```java
public class Bank
{
    private double[] accounts;
    private var lock = new Object();
    ...;
    public void transfer(int from, int to, int amount)
    {
        synchronized(lock) //an ad-hoc lock
        {
            accounts[from] -= amount;
            accounts[to] += amount;
        }
        System.out.println(...);
    }
}
```

这里创建lock对象只是为了使用每个对象拥有的锁。

有时程序员使用一个对象的锁来实现额外的原子操作， 这种方法称为**客户端锁定（client-side locking）**

```java
public void transfer(Vector<double> accounts, int from, int to, int amount)
{
    synchronized(accounts)
    {
        accounts.set(from, accounts.get(from) - amount);
        accounts.set(to, accounts.get(to) + amount);
    }
    System.out.println(...);
}
```

通过截获accounts的锁， 避免在transfer方法中被抢占

但这个方法依赖一个事实： Vector类会对自己的所有更改方法使用内部锁。

客户端锁定非常脆弱， 不推荐使用。



## 监视器概念

不要求程序员使用显式锁就可以保证多线程的安全的最成功的解决方案之一是**监视器（monitor）**

监视器具有如下特性：

* 监视器只包含私有字段的类
* 监视器类的每个对象有一个关联的锁
* 所有方法由这个锁锁定
* 锁可以有任意多个相关联的条件



## volatile字段

volatile关键字为实例字段的同步访问提供了一种免锁机制， 若声明一个字段为volatile, 那么编译器和虚拟机就知道该字段可能被另一个线程并发更新。

```java
private boolean done;
public synchronized boolean isDone() {return done;}
public synchronized void setDone() {done = true;}
```

如果另一个线程已经对该对象加锁， isDone和setDone方法可能会阻塞， 可以只为这个变量使用一个单独的锁， 但是这很麻烦。

```java
private volatile boolean done;
public boolean isDone() {return done;}
public void setDone() {done = true;}
```

编译器会插入适当的代码， 以确保如果一个线程对done变量做了修改， 这个修改对这个变量的所有其他线程都可见。

## final变量

```java
final var accounts = new HashMap<String, Double>();
```

对这个映射的操作并不是线程安全的， 如果有多个线程更改和读取这个映射， 仍然需要同步。

## 原子性

假设对共享变量除了赋值之外并不做其他操作， 那么可以将这些共享变量声明为volatile。

java.util.concurrent.atomic 包中很多类使用了非常高效的机器指令来保证其他操作的原子性

```java
public static AtomicLong nextNumber = new AtomicLong();
//in some thread;
long id = nextNumber.incrementAndGet();
```

如果希望完成更加复杂的更新， 必须使用compareAndSet方法

```java
public static AtomicLong largest = new AtomicLong();
// in some thread
largest.updateAndGet(x->Math.max(x, observed));
// or
largest.accumlatteAndGet(observed, Math::max);
```



如果有大量线程访问相同的原子值， 性能会大幅下降。

此时需要使用过LongAdder和LongAccumulator类解决该问题。

如果预期可能存在大量竞争， 只需要使用LongAdder而不是AtomicLong。

```java
var adder = new LongAdder();
for(...)
    pool.submit(() ->{
        while(...){
            ...
            if(...) adder.increment();
        }
    }
);
...
long total = adder.sum();
```



longAccumulator将这种思想推广到任意的累加操作， 在构造器中， 可以提供这个操作以及它的零元。

```java
var adder = new LongAccumulator(Long::sum, 0);
// in some thread...
adder.accumulate(value);
```

## 死锁

锁和条件不能解决多线程出现的所有问题

有可能会因为每一个线程要等待其他更多的线程都被阻塞， 这种状态称之为**死锁（deadlock）**



## 线程局部变量

使用ThreadLocal辅助类为各个线程提供各自的实例。

```java
public static final ThreadLocal<SimpleDateFormat> dateFormat =  ThreadLocal.withInitial(() -> new SimpleDateFormat("yyyy-mm-dd"));
```

要访问具体的格式化方法， 可以调用

```java
String dateStamp = dateFormat.get().format(new Date());
```

```java
int random = ThreadLocalRandom.current().nextInt(upperBound);
```

## 线程安全的集合

## 阻塞队列

当试图向队列添加元素而队列已满， 或是想从队列移除元素而队列为空， **阻塞队列（blocking queue）** 将导致线程阻塞

阻塞队列方法分为以下三类： 

1.  如果使用队列作为线程管理工具， 将要用到put和take方法
2. 当试图向满队列添加元素或想从空队列中得到队头元素时， add, remove和element方法抛出异常
3. 在一个多线程程序中， 队列可能会在任何时候变空或变满， 因此应当使用offer， poll和peek方法作为替代



还有带有超时时间的offer方法和poll方法

```java
boolean success == q.offer(x, 100, TimeUnit.MILLISECONDS);
```

会在100毫秒的时间内在队尾插入一个元素， 成功返回true

```java
Object head = q.poll(100, TimeUnit.MILLISECONDS);
```



java7增加了一个TransferQueue接口，允许生产者线程等待， 直到消费者准备就绪可以接受元素。

```java
q.transfer(item);
```

这个调用会阻塞， 直到另一个线程将元素（item）删除。



```java
package blockingQueue;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.concurrent.*;
import java.util.stream.*;
import java.util.*;

/**
 * @author Cay Horstmann
 */
public class BlockingQueueTest 
{
    private static final int FILE_QUEUE_SIZE = 10;
    private static final int SEARCH_THREADS = 100;
    private static final Path DUMMY = Path.of("");
    private static BlockingQueue<Path> queue = new ArrayBlockingQueue<>(FILE_QUEUE_SIZE);
    public static void main(String[] args) 
    {
        try (var in = new Scanner(System.in))
        {
            System.out.print("Enter base directory (e.g. /opt/jdk-9-src):");
            String directory = in.nextLine();
            System.out.print("Enter keyword (e.g. volatile)");
            String keyword = in.nextLine();

            Runnable enumerator = () ->{
                try{
                    enumerate(Path.of(directory));
                    queue.put(DUMMY);
                }
                catch (IOException e)
                {
                    e.printStackTrace();
                }
                catch (InterruptedException e)
                {

                }
            };
            new Thread(enumerator).start();
            for(int i = 1; i <= SEARCH_THREADS; i++)
            {
                Runnable searcher = () ->{
                    try
                    {
                        var done = false;
                        while (!done)
                        {
                            Path file = queue.take();
                            if(file == DUMMY)
                            {
                                queue.put(file);
                                done = true;
                            }
                            else search(file, keyword);
                        }
                    }
                    catch(IOException e)
                    {
                        e.printStackTrace();
                    }
                    catch(InterruptedException e)
                    {

                    }
                };
                new Thread(searcher).start();
            }
        }
    }

    /**
     * Recursively enumerates all files in a given directory and its subdirectories.
     * See Chapters 1 and 2 of Volume Ⅱ for the stream and file operations.
     * @param directory the directory in which to start 
     */
    public static void enumerate(Path directory) throws IOException, InterruptedException
    {
        try (Stream<Path> children = Files.list(directory))
        {
            for (Path child: children.collect(Collectors.toList()))
            {
                if(Files.isDirectory(child))
                    enumerate(child);
                else
                    queue.put(child);
            }
        }
    }


    /**
     * Searches a file for a given keyword and prints all matching lines.
     * @param file the file to search
     * @param keyword the keyword to search for 
     */
    public static void search(Path file, String keyword) throws IOException
    {
        try (var in = new Scanner(file, StandardCharsets.UTF_8))
        {
            int lineNumber = 0;
            while(in.hasNextLine())
            {
                lineNumber++;
                String line = in.nextLine();
                if(line.contains(keyword))
                    System.out.printf("%s: %d: %s%n", file, lineNumber, line);
            }
        }
    }   
}
```

 ## 高效的映射， 集和队列

java.util.concurrent包提供了映射， 有序集， 和队列的高效实现 ： ConcurrentHashMap, ConcurrentSkipListMap, ConcurrentSkipListSet和ConcurrentLinkedQueue.

这些集合通过允许并发地访问数据结构的不同部分尽可能地减少竞争。

这些类的size()不一定在常数时间内完成操作， 确定这些集合的大小通常需要遍历

集合返回**弱一致性（weakly consistent）**的迭代器， 这意味着迭代器不一定能反映出它们构造之后的所有更改。

* 弱一致性：不能保证任何一次读都能读到最近一次写入的数据，但能保证最终可以读到写入的数据，单个写锁+ 无锁读，就是弱一致性的一种实现。

并发散列构造可以高效地支持大量阅读器和一定数量的书写器。 默认情况下认为可以有至多16个同时运行的书写器。 若同一时间多于16个， 其余线程将暂时阻塞。

## 映射条目的原子更新

```java
Long oldValue = map.get(word);
Long newValue = oldValue == null ? 1: oldvalue + 1;
map.put(word, newValue);
```

这样的代码显然是线程不安全的

调用compute方法时可以提供一个键和一个计算新值的函数， 这个函数接受键和相关联的值（若没有值， 则为null）

```java
map.compute(word, (k, v) -> v == null ? 1 : v + 1);
```

* ComcurrentHashMap中不允许值为null， 很多方法使用null表示映射中给定的键不存在



还有computeIfPresent和computeIfAbsent方法， 分别只在已经有原值的情况下计算新值或这只在没有原值的情况下计算新值。

```java
map.computeIfAbsent(word, k -> new LongAdder()).increment();
```



首次增加一个键时通常需要一些特殊处理， 利用merge方法可以方便地做到。这个方法有一个参数表示键不存在时使用的初始值， 否则就会调用提供的函数来结合原值和初始值。

```java
map.merge(word, 1L, Long::sum);
```

以下程序使用并发散列映射统计 一个目录树下的所有java文件

```java
package concurrentHashMap;

import java.io.IOException;
import java.util.concurrent.*;
import java.nio.file.*;
import java.util.*;
import java.util.stream.*;


/**
 * This program demostrates concurrent hash maps.
 * @author Cay Horstmann
 */
public class CHMDemo
{
    public static ConcurrentHashMap<String, Long> map = new ConcurrentHashMap<>();

    public static void main(String[] args) throws InterruptedException, ExecutionException, IOException
    {
        int processors = Runtime.getRuntime().availableProcessors();
        ExecutorService executor = Executors.newFixedThreadPool(processors);
        Path pathToRoot = Path.of(".");
        for (Path p : descendants(pathToRoot))
        {
            if(p.getFileName().toString().endsWith(".java"))
                executor.execute(() -> process(p));
        }
        executor.shutdown();
        executor.awaitTermination(10, TimeUnit.MINUTES);
        map.forEach((k, v) ->
        {
            if(v >= 10)
                System.out.println(k + " occurs " + v + " times");
        });
    }
    /**
     * Adds all words in the given file to the concurrent hash map.
     * @param file a file
     */
    public static void process(Path file)
    {
        try(var in = new Scanner(file))
        {
            while(in.hasNext())
            {
                String word = in.next();
                map.merge(word, 1L, Long::sum);
            }
        }
        catch(IOException e)
        {
            e.printStackTrace();
        }
    }
    /**
     * Returns all decendants of a given directory--see Chapters 1 and 2 of Volume Ⅱ。
     * @param rootDir the root directory
     * @return a set of all descendants of the root directory.
     */
    public static Set<Path> descendants (Path rootDir) throws IOException
    {
        try (Stream<Path> entries = Files.walk(rootDir))
        {
            return entries.collect(Collectors.toSet());
        }
    }
}
```

## 对并发散列映射的批操作

即便有其他线程在处理映射， 这些操作也能安全执行。

批操作会遍历映射， 处理遍历过程中找到的每一个元素。

有三种不同的操作：

1. search（搜索）为每一个键或值应用一个函数， 直到函数生成一个非null结果。然后搜索终止
2. reduce（归约）组合所有键或值。 这里要使用所提供的一个累加函数。
3. forEach为所有键或值应用一个函数

每个操作有4个版本：

1. operationKeys: 处理键
2. operationValues: 处理值
3. operation： 处理键和值
4. operationEntries： 处理Map.Entry对象

对于以上操作， 需要指定一个参数化阈值（parallelism threshold）。如果映射包含的元素多于这个阈值， 就会完成并行批操作。

```java
String result = map.search(threshold, (k, v) -> v > 1000? k: null);
```

forEach方法有两种形式： 

1. ```java
   map.forEach(threshold, (k, v) -> System.out.println( k + " -> " + v))
   ```

   第一种形式只对各个映射条目应用一个消费者函数

   第二种形式还有一个额外的转换器参数：

2. ```java
   map.forEach(threshold, 
              (k, v) -> k + " -> " + v, 
              System.out::println);
   ```

转换器可以用作一个过滤器， 只要转换器返回null, 这个值就会被跳过

```java
map.forEach(threshold, 
           (k, v) -> v > 1000 ? k + " -> " + v: null,
           System.out::println);
```



reduce操作用一个累加操作组合器输入

```java
Long sum = map.reduceValue(threshold, Long::sum);
```

也可以提供一个转换器

```jaba
Integer maxlength = map.reduceKeys(threshold,
v ->v > 1000? 1L : null, Long::sum);
```

## 并发集视图

假设想要的是一个很大的线程安全的集儿非映射， 并没有ConcurrentHashSet类。

静态方法newKeySet方法生成一个Set< K >, 这实际是ConcurrentHashMap< K , Boolean >的一个包装器

```java
Set<String> words = ConcurrentHashMap.<String>newKeySet();
```

## 写数组的拷贝

CopyOnWriteArrayList和CopyOnWriteArraySet是线程安全的集合， 所有的更改器会建立底层数组的一个副本。

如果这个数组后来被更改了， 迭代器仍然引用旧数组， 但是集合的数组已经替换

## 并行数组算法



静态Arrays.parallelSort方法可以对一个基本类型值或对象数组排序

```java
var contents = new String(Files.readAllBytes(Path.of("alice.txt")), StandardCharSets.UTF_8);
String [] words = contents.split("[\\P{L}+]");
Arrays.parallelSort(words);
```

可以提供一个Comparator

```java
Arrays.parallelSort(words, Comparator.comparing(String::length))
```

对于所有方法都可以提供一个范围的边界

```java
values.parallelSort(values.length / 2, values.length);
```

## 较早的线程安全集合

任何集合类都可以使用同步包装器（synchronization wrapper）变成线程安全的

```java
List <E> synchArrayLisy = Collections.synchronizedList(new ArrayList<E>());
Map <K, V> synchHashMap = Collections.synchronizedMap(new HashMap<K, V>());
```





# 任务和线程池

## Callable 与 Future

Callable与Runnable类似, 但是有返回值

```java
public interface Callable<V>
{
    v call() throws Exception;
}
```

Future保存异步计算的结果， 可以启动一个计算， 将Future对象交给某个线程。

执行Callable的一种方法是使用FutureTask.

``` java
Callable<Integer> task = ...;
var futureTask = new FutureTask<Integer>(task);
var t = new Thread(futureTask);
t.start();
...;
Integer result = task.get(); 	// it's a Future
```



## 执行器

|               方法               |                             描述                             |
| :------------------------------: | :----------------------------------------------------------: |
|       newCachedThreadPool        |              必要时创建新线程， 空闲线程保留60s              |
|        newFixedThreadPool        |           池中包含固定数量线程； 空闲线程一直保留            |
|       newWorkStealingPool        | 一种适合“fork-join”任务的线程池·， 其中复杂的任务会分解为更简单的任务， 空闲线程会"密取"较简单的任务 |
|     newSingleThreadExecutor      |        只有一个线程的”池“， 会顺序地执行所提交的任务         |
|      newScheduledThreadPool      |                   用于调度执行的固定线程池                   |
| newSingleThreadScheduledExecutor |                   用于调度执行的单线程”池“                   |

 单线程执行器对于性能分析很有帮助。

可以用

```java
Future<T> submit(Callable<T> task)
Future<?> submit(Runnable task)
Future<T> submit(Runnable task, T result)
```

submit方法将会得到一个Future对象， 可以用来得到结果或取消任务。



使用完一个线程池后调用shutdown, 这个方法启动线程池的关闭序列

。 被关闭的执行器不再接受新的任务， 当所有任务完成， 线程池中的线程死亡。

shutdownNow方法会取消所有尚未开始的任务。



## 控制任务组

invokeAny方法提交一个Callable对象集合中的所有对象， 并返回某个已完成任务的结果。

invokeAll方法提交一个Callable对象集合中的所有对象， 这个方法会阻塞， 直到所有任务完成， 并返回表示所有任务答案的一个Future对象列表。

得到结果后：

```java
List<Callable<T>> tasks = ...;
List<Future<T>> results = exeutor.invokeAll(tasks);
for (Future<T> result : results)
    processFurther(result.get());
```



很有必要按计算出结果的顺序得到这些结果， 故使用ExecutorCompletionService来管理

以下组织更加高效：

```java
var service = new ExecutorCompletionService<T>(executor);
for(Callable<T> task: tasks) service.submit(task);
for (int i = 0; i < tasks.size(); i++)
    processFurther(service.take().get());
```

```java
package executors;

import java.io.IOException;
import java.util.*;
import java.nio.file.*;
import java.util.concurrent.*;
import java.util.stream.*;
import java.time.*;

/**
 * This program demostrates the Callable interface and executors.
 * @author Cay Horstmann
 */
public class ExecutorDemo
{
    /**
     * Counts occurences of a given word in a file.
     * @return the number of times the word occurs in the given word
     */
    public static long occurences(String word, Path path)
    {
        try(var in = new Scanner(path))
        {
            int count = 0;
            while(in.hasNext())
                if(in.next().equals(word))
                    count++;
            return count;
        }
        catch (IOException ex)
        {
            return 0;
        }
    }

    /**
     * Returns all descendants of a given directory--see Chapters 1 and 2 of Volume Ⅱ.
     * @param rootDir the root directory
     * @return a set of all decendants of the root directory
     */
    public static Set<Path> descendants (Path rootDir) throws IOException
    {
        try (Stream<Path> entries = Files.walk(rootDir))
        {
            return entries.filter(Files::isRegularFile)
                    .collect(Collectors.toSet());
        }
    }

    /**
     * Yield a task that searchs for a word in a file.
     * @param word to search
     * @param path the file to search
     * @return the search task that yields the path upon success
     */
    public static Callable<Path> searchForTask(String word, Path path)
    {
        return () ->
        {
            try (var in = new Scanner(path))
            {
                while(in.hasNext())
                {
                    if(in.next().equals(word)) return path;
                    if(Thread.currentThread().isInterrupted())
                    {
                        System.out.println("Search in " + path + " canceled.");
                        return null;
                    }
                }
                throw new NoSuchElementException();
            }
        };
    }

    public static void main(String[] args)  throws IOException, InterruptedException, ExecutionException
    {
        try(var in = new Scanner(System.in))
        {
            System.out.print("Enter base directory (e.g. /opt/jdk-9-src): ");
            String start = in.nextLine();
            System.out.print("Enter keyword (e.g. volatile): ");
            String word = in.nextLine();

            Set<Path> files = descendants(Path.of(start));
            var tasks = new ArrayList<Callable<Long>>();
            for (Path file: files)
            {
                Callable<Long> task = () ->occurences(word, file);
                tasks.add(task);
            }
            ExecutorService executor = Executors.newCachedThreadPool();
            //use a single thread executor instead to see if mutiple threads
            // speed up the search
            // ExecutorService executor = Executors.newSingleThreadExecutor();

            Instant startTime = Instant.now();
            List<Future<Long>> results = executor.invokeAll(tasks);
            long total = 0;
            for (Future<Long> result: results)
                total += result.get();
            Instant endTime = Instant.now();
            System.out.println("Occurences of " + word + ": " + total);
            System.out.println("Time elapsed: "
            +Duration.between(startTime, endTime).toMillis() + "ms");

            var searchTasks = new ArrayList<Callable<Path>>();
            for(Path file: files)
                searchTasks.add(searchForTask(word, file));
            Path found = executor.invokeAny(searchTasks);
            System.out.println(word + " occurs in: " + found);

            if(executor instanceof ThreadPoolExecutor)
                System.out.println("Largest pool size: "
                + ((ThreadPoolExecutor)executor).getLargestPoolSize());
            executor.shutdown();
        }
    }
}
```

阿里的代码要求中， 只允许使用线程池调用线程。

## fork-join框架

fork-join框架为完成密集型任务， 如图像或视频处理的线程提供支持

```java
if (problemsize < threshold)
    solve problem directly
else
{
    break problem into subproblems
        recursively solve each subproblem
        combine the results
}
```

若要采用框架可用的一种方法完成该递归运算， 需要提供一个扩展RecursiveTask< T >的类或者提供一个扩展RecursiveAction的类。再覆盖compute方法来生成并调用子任务， 然后合并其结果

```java
class Counter extends RecursiveTask<Integer>
{
	...
	protected Integer compute()
	{
  	  if(to - from < THRESHOLD)
    	{
       		 solve problem directly
    	}
    	else
    	{
        	int mid = (from + to) / 2;
        	var first = new Counter(values, from, mid, filter);
        	var second = new Counter(values, mid, to, filter);
        	invokeAll(first, second);
        	return first.join() + second.join();
    	}
    }
}
```



```java
package forkJoin;

import java.util.concurrent.*;
import java.util.function.DoublePredicate;

/**
 * This program demonstrates the fork-join framework.
 * @author Cay Horstmann
 */

public class ForkJoinTest
{
    public static void main(String[] args) {
        final int SIZE = 10000000;
        var numbers = new double[SIZE];
        for (int i = 0; i < SIZE; i++)
            numbers[i] = Math.random();
        var counter = new Counter(numbers, 0, numbers.length, x->x > 0.5);
        var pool = new ForkJoinPool();
        pool.invoke(counter);
        System.out.println(counter.join());
    }
}

class Counter extends RecursiveTask<Integer>
{
    public static final int THRESHOLD = 1000;
    private double[] values;
    private int from;
    private int to;
    private DoublePredicate filter;
    
    public Counter(double[] values, int from, int to, DoublePredicate filter)
    {
        this.values = values;
        this.from = from;
        this.to = to;
        this.filter = filter;
    }
    
    protected Integer compute()
    {
        if(to - from < THRESHOLD)
        {
            int count = 0;
            for (int i = from; i < to; i++)
            {
                if (filter.test(values[i])) count++;
            }
            return count;
        }
        else
        {
            int mid = (from + to) / 2;
            var first = new Counter(values, from, mid, filter);
            var second = new Counter(values, mid, to, filter);
            invokeAll(first, second);
            return first.join() + second.join();
        }
    }
}
```



在后台fork-join框架使用了一种有效的智能方法来平衡可用线程的工作负载， 这种方法称为**工作密取（work stealing）** 每个工作线程都有一个双端队列（deque）来完成让任务。



# 异步计算

## 可完成Future

CompletableFuture实现了Future接口， 提供了另一种获得结果的机制。 

首先要注册一个回调， 当结果可用， 就会利用该结果调用这个回调。

```java
CompletableFuture<String> f = ...;
f.thenAccept(s-> Process the result string s);
```

```java
HttpClient client = HttpClient.newHttpClient();
HttpRequest request = HttpRequest.newBuilder(URI.create(urlString)).GET().build();
CompletableFuture<HttpResponse<String>> f = client.sendAsync(
request, BodyHandler.asString());
```

要想异步运行任务并得到CompletableFuture， 不要把它直接提交给执行器服务， 应当调用静态方法CompletableFuture.supplyAsync。

```java
    public CompletableFuture<String> readPage(URL url)
    {
        return CompletableFuture.supplyAsync(() ->
                {
                    try
                    {
                        return new String(url.openStream().readAllBytes(), "UTF-8");
                    }
                    catch(IOException e)
                    {
                        throw new UncheckedIOException(e);
                    }
                }, executor);
    }
```

如果忽略执行器， 任务会在一个默认执行器上运行



要处理CompletableFuture两种完成的方式， 可以使用whenComplete方法。

```java
f.whenComplete((s, t)->
               {
                   if(t == null) {process the result s;}
                   else {Process the Throwable t;}
               });
```

当使用supplyAsync创建一个CompletableFuture时， 任务完成时就会隐式设置完成值。 这样的对象称为**承诺（promise）**

显式设置结果可以提供更大的灵活性

```java
var f = new CompletableFuture<Integer>();
executor.execute(() -> 
                 {
                     int n = workHard(arg);
                     f.complete(n);
                 });
executor.execute(() ->
                 {
                     int n = workSmart(arg);
                     f.complete(n);
                 });
```

要对一个异常完成future

```java
Throwable t = ...;
f.completeExecptionally(t);
```

## 组合可完成Future

非阻塞调用通过回调实现

```java
package completableFutures;

import java.awt.image.*;
import java.io.*;
import java.io.UncheckedIOException;
import java.nio.charset.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.regex.*;
import java.net.*;
import javax.imageio.*;

public class CompletableFutureDemo 
{
    private static final Pattern IMG_PATTERN = Pattern.compile(
            "[<]\\s*[iI][mM][gG]\\s*[^>][rR][cC]\\s*['\"]([^'\"])['\"][^>]*[>]");
    private ExecutorService executor = Executors.newCachedThreadPool();
    private URL urlToProcess;
    
    public CompletableFuture<String> readPage(URL url)
    {
        return CompletableFuture.supplyAsync(() -> 
        {
           try
           {
               var contents = new String(url.openStream().readAllBytes(),
                       StandardCharsets.UTF_8);
               System.out.println("Read page from " + url);
               return contents;
           }
           catch (IOException e)
           {
               throw new UncheckedIOException(e);
           }
               
        }, executor);
    }
    
    public List<URL> getImageURLs(String webpage)   //not time-consuming
    {
        try
        {
            var result = new ArrayList<URL>();
            Matcher matcher = IMG_PATTERN.matcher(webpage);
            while(matcher.find())
            {
                var url = new URL(urlToProcess, matcher.group(1));
                result.add(url);
            }
            System.out.println("Found URLs: " + result);
            return result;
        }
        catch (IOException e)
        {
            throw new UncheckedIOException(e);
        }
    }
    public CompletableFuture<List<BufferedImage>> getImages(List<URL> urls)
    {
        return CompletableFuture.supplyAsync(() ->
        {
            try
            {
                var result = new ArrayList<BufferedImage>();
                for (URL url :
                        urls) {
                    result.add(ImageIO.read(url));

                    System.out.println("Loaded " + url);
                }
                return result;
            }
            catch(IOException e)
            {
                throw new UncheckedIOException(e);
            }
        }, executor);
    }
    public void saveImage(List<BufferedImage> images) {
        System.out.println("Saving " + images.size() + " images");
        try
        {
            for (int i = 0; i < images.size(); i++) {
                String filename = "/tmp/image" + (i + 1) + ".png";
                ImageIO.write(images.get(i),  "PNG", new File(filename));
            }
        }
        catch (IOException e)
        {
            throw new UncheckedIOException(e);
        }
        executor.shutdown();
    }
    public void run(URL url) throws IOException, InterruptedException
    {
        urlToProcess = url;
        CompletableFuture.completedFuture(url)
                .thenComposeAsync(this::readPage, executor)
                .thenApply(this::getImageURLs)
        .thenCompose(this::getImages)
        .thenAccept(this::saveImage);
        
    }

    public static void main(String[] args) throws IOException, InterruptedException
    {
        new CompletableFutureDemo().run(new URL("http://horstmann.com/index.html")); 
    }
}
```



# 进程

Process类再一个单独的操作系统进程中执行一个命令， 允许我们与stdin， stdout， stderr进行交互。ProcessBuilder类则允许我们配置Process对象。

# 建立一个进程

```java
var builder = new ProcessBuilder("gcc", "test.c");
```

要在windows中运行dir命令， 需要提供字符串“cmd.exe” “/c"和 ”dir"来建立进程

默认下进程工作目录与虚拟机相同, 可以用directory方法修改

```java
builder = builder.directory(path.toFile());
```

可以指定新进程的输入， 输出和错误流与JVM相同。

```java
builder.redirectIO();
```

```java
builder.redirectOutput(ProcessBuilder.Redirect.INHERIT);
```

 进程启动时， 会创建或删除输出和错误文件， 若要追加到现有文件

```java
builder.redirectOutput(ProcessBuilder.Redirect.appendTo(outputFile));
```

## 运行一个进程

配置构建器后， 要调用其start方法启动进程

```java
Process process = new ProcessBuilder("/bin/ls", "-l")
    .directory(Path.of("/tmp").toFile())
    .start();
try (var in = new Scanner(process.getInputStream())) {
    while(in.hasNextLine())
        System.out.println(in.nextLine());
}
```



要等待进程完成

```java
 int result = process.waitFor();
```

或限时等待

```java
long delay = ...;
if(process.waitfor(delay, TimeUnit.SECONDS)){
    int result = process.exitValue();
    ...
}else{
    process.destoryForcibly();
}
```

















