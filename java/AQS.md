# AQS 的引入

## LockSupport

`AQS` 底层依赖`LockSupport`实现。

`LockSupport`底层实现借由Unsafe中的`native`方法

与`Object`的`notify`和`notifyAll`方法不同， LockSupport可以指定固定的`Thread`唤醒

实现三个线程顺序打印ABC:

```java
public class LockSupportTest{
    private void printA(Thread thread){
        try{
            Thread.sleep(20L);
            System.out.println("A");
            LockSupport.unpark(thread);
        }catch(InterruptedException e){
            e.printStackTrace();
        }
    }
    private void printB(Thread thread){
        try{
            Thread.sleep(10L);
            LockSupport.park();
            System.out.println("B");
            LockSupport.unpark(thread);
        }catch(InterruptedException e){
            e.printStackTrace();
        }
    }
    private void printC(){
        try{
            Thread.sleep(10L);
            LockSupport.park();
            System.out.println("C");
        }catch(InterruptedException e){
            throw new RuntimeException(e);
        }
    }
    public static void main(String[] args) {
        var lockSupportTest = new LockSupportTest();
        var tC = new Thread(lockSupportTest::printC);
        var tB = new Thread(() -> lockSupportTest.printB(tC));
        var tA = new Thread(() -> lockSupportTest.printA(tB));
        tA.start();
        tB.start();
        tC.start();
    }
}
```

## ReentrantLock

```java
public class ReentrantLockTest {
    private Lock lock = new ReentrantLock();
    private volatile int num = 0;
    private int getNum() {
        return num;
    }
    private void addNum(){
        lock.lock();
        try{
            Thread.sleep(5L);
            num++;
        }catch(InterruptedException e){
            throw new RuntimeException(e);
        }finally{
            lock.unlock();
        }
    }
    public static void main(String[] args) throws InterruptedException{
        var test = new ReentrantLockTest();
        for (int i = 0; i < 100; i++) {
            new Thread(test::addNum).start();
        }
        Thread.sleep(1000L);
        System.out.println(test.getNum());  
    }  
}
```

## Lock

```java
//Lock.java 
void lock();
    void lockInterruptibly() throws InterruptedException;
    boolean tryLock();
    boolean tryLock(long time, TimeUnit unit) throws InterruptedException;
    void unlock();

```

观察ReentrantLock的具体实现

```java
    public void lock() {
        sync.lock();
    }
    public void lockInterruptibly() throws InterruptedException {
        sync.lockInterruptibly();
    }
    public boolean tryLock() {
        return sync.tryLock();
    }
```

操作基本都由`sync`代理实现。

```java
abstract static class Sync extends AbstractQueuedSynchronizer{
    //...
            final void lock() {
            if (!initialTryLock())
                acquire(1);
            }
    //...

}
```

`Sync`的默认实现分别是`FairSync`和`NonfairSync`

```java
static final class NonfairSync extends Sync {
        private static final long serialVersionUID = 7316153563782823691L;
        final boolean initialTryLock() {
            Thread current = Thread.currentThread();
            if (compareAndSetState(0, 1)) { // first attempt is unguarded
                setExclusiveOwnerThread(current);
                return true;
            } else if (getExclusiveOwnerThread() == current) {
                int c = getState() + 1;
                if (c < 0) // overflow
                    throw new Error("Maximum lock count exceeded");
                setState(c);
                return true;
            } else
                return false;
        }

        /**
         * Acquire for non-reentrant cases after initialTryLock prescreen
         */
        protected final boolean tryAcquire(int acquires) {
            if (getState() == 0 && compareAndSetState(0, acquires)) {
                setExclusiveOwnerThread(Thread.currentThread());
                return true;
            }
            return false;
        }
    }
```

`ReentrantLock`默认使用`UnfairSync`

