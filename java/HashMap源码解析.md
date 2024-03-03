# HashMap源码解析

## 头注释

这一段说的是HashMap运行null key and null value, and it is unsynchronized.

and interation time is proportional to the capacity of the HashMap Instance.

If you want high speed of iteration, do not set the initial capacity too high(or the load factor too low).

当超过load factor * current capacity 时， 内部桶翻两倍。

default load factor is 0.75.

当存储键值类为Comparable时，来解决一定的哈希冲突。

可以使用Collections.synchronizedMap(HashMap)来得到一个线程安全的HashMap（HashTable 是线程安全的， 同时不支持null键值对）。

这个类的所有Iterator是fail-fast的。

![image-20220721232835898](https://s2.loli.net/2022/07/21/qLINg7nmadTPSfw.png)

![image-20220721232912630](https://s2.loli.net/2022/07/21/QKc9LWj7kqAHCUn.png)

## 字段解析

初始容量为16。

默认load factor为0.75（符合0.5的泊松分布）

treeify threshold 为 8（超过8后，红黑树遍历性能大于链表）.

![image-20220721235750657](https://s2.loli.net/2022/07/21/NxYfUmAiGRO4Try.png)

这里看来是节点还缓存了hashCode

![image-20220722000032993](https://s2.loli.net/2022/07/22/nAUgxlfWi6ysFT3.png)

这个静态方法看起来是判断Comparable的

![image-20220722000326598](C:\Users\Yuki\AppData\Roaming\Typora\typora-user-images\image-20220722000326598.png)

## TreeifyBin

判断length是否大于树化长度阈值， 如果不大于则扩容，反之将节点转换为树节点，最后进行树化。

```java
final void treeifyBin(Node<K,V>[] tab, int hash) {
        int n, index; Node<K,V> e;
        if (tab == null || (n = tab.length) < MIN_TREEIFY_CAPACITY)
            resize();
        else if ((e = tab[index = (n - 1) & hash]) != null) {
            TreeNode<K,V> hd = null, tl = null;
            do {
                TreeNode<K,V> p = replacementTreeNode(e, null);
                if (tl == null)
                    hd = p;
                else {
                    p.prev = tl;
                    tl.next = p;
                }
                tl = p;
            } while ((e = e.next) != null);
            if ((tab[index] = hd) != null)
                hd.treeify(tab);
        }
    }
```

