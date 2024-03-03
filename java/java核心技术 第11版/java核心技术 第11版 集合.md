@[TOC](java 核心技术第11版  集合)

# java集合框架



## 集合接口与实现分离



java集合类库将接口与实现（implementation）分离

队列通常有两种实现方式， 一种是使用循环数组， 一种是使用链表。



可以使用接口类型存放集合引用

```java
Queue<Customer> expressLane = new CircularArrayQueue<>(100);
expressLane.add(new Customer("Harry"));
```

循环数组容量有限

API文档中有一组以Abstract开头的类， 这些类是为类库实现者设计的， 若想要实现自己的队列类， 扩展AbstractQueue类比实现Queue接口中所有方法轻松得多

## Collection接口

集合类的基本接口是Collection接口

```java
public interface Collection<E>
{
    boolean add(E element);
    Iterator<E> iterator();
    ...
}
```

## 迭代器

Iterator接口包含四个方法

```java
public interface Iterator<E>
{
    E next();
    boolean hasNext();
    void remove();
    default void forEachRemaining(Consumer<? super E> action);
}
```

使用next方法可以诸葛访问集合中的元素， 若到达集合末尾， 则抛出一个NoSuchElementException。

```java
Collection<String> c = ...;
Iterator<String> iter = c.iterator();
while (iter.hasNext())
{
    String element = iter.next();
    do something with element
}
```

for each循环更加简练

```java
for (String element: c)
{
    do something with element
}
```

也可以调用forEachRemaining方法， 其将对每一个元素调用Iambda表达式

```java
iterator.forEachRemaining(element -> do something with the element);
```



可以将Iterator.next与Inputstream.read看成等效的。

remove会删除上次调用next时返回的元素

```java
Iterator<String> it = c.iterator();
it.next();
it.remove();
```

若想删除两个相邻的元素

```java
it.remove();
it.next();
it.remove();
```

## 泛型实用方法

可以编写任何处理集合类型的实用方法

```java
public static <E> boolean contains(Collection<E> c, Object obj)
{
    for (E element : c)
    {
        if (element.equals(obj))
            return true;
    }
    return false;
}
```

Collection接口声明了很多有用的方法， 所有实现类都必须提供这些方法

AbstractCollection类保持基础方法size和iterator仍为抽象方法， 但是为实现者实现了其他例行方法

```java
public abstract class AbstractCollection<E>
    implements Collection<E>
{
    ...
    public abstract Iterator<E> iterator();
    
    public boolean contains(Object obj)
    {
        for (E element: this) // calls iterator()
            if(element.equals(obj))
                return true;
        return false;
    }
    ...
}
```

Collection接口还有一个很好用的方法

```java
default boolean removeIf(Predicate<? super E> )
```



### API

java.util.Collection<E>

* ```
  Iterator<E>
  iterator()
  ```

  Returns an iterator over the elements in this collection.

* ```
  int
  size()
  ```

  Returns the number of elements in this collection.

* ```
  boolean
  isEmpty()
  ```

  Returns `true` if this collection contains no elements.

* ```
  boolean
  contains(Object o)
  ```

  Returns `true` if this collection contains the specified element.

* ```
  boolean
  containsAll(Collection<?> c)
  ```

  Returns `true` if this collection contains all of the elements in the specified collection.

* ```
  boolean
  add(E e)
  ```

  Ensures that this collection contains the specified element (optional operation).

* ```
  boolean
  addAll(Collection<? extends E> c)
  ```

  Adds all of the elements in the specified collection to this collection (optional operation).

* ```
  boolean
  remove(Object o)
  ```

  Removes a single instance of the specified element from this collection, if it is present (optional operation).

* ```
  boolean
  removeAll(Collection<?> c)
  ```

  Removes all of this collection's elements that are also contained in the specified collection (optional operation).

* ```
  default boolean
  removeIf(Predicate<? super E> filter)
  ```

  Removes all of the elements of this collection that satisfy the given predicate.

* ```
  void
  clear()
  ```

  Removes all of the elements from this collection (optional operation).

* ```
  boolean
  retainAll(Collection<?> c)
  ```

  Retains only the elements in this collection that are contained in the specified collection (optional operation).

* ```
  Object[]
  toArray()
  ```

  Returns an array containing all of the elements in this collection.

* ```
  <T> T[]
  toArray(T[] a)
  ```

  Returns an array containing all of the elements in this collection; the runtime type of the returned array is that of the specified array.



java.util.Iterator< E >

* ```
  default void
  forEachRemaining(Consumer<? super E> action)
  ```

  Performs the given action for each remaining element until all elements have been processed or the action throws an exception.

* ```
  boolean
  hasNext()
  ```

  Returns `true` if the iteration has more elements.

* ```
  E
  next()
  ```

  Returns the next element in the iteration.

* ```
  default void
  remove()
  ```

  Removes from the underlying collection the last element returned by this iterator (optional operation).



# 集合框架中的接口



集合有两个基本接口： Collection和Map

映射用put方法插入

```java
V put (K key, V value)
```

读取使用get方法

```java
V get (K key)
```

List是一个有序集合（ordered collection）。

List定义了多个随机访问的方法

```java
void add(int index, E element)
void remove (int index)
E get (int index)
E set (int index, E element)
```

ListIterator接口定义了一个方法用于在迭代器前面增加一个元素

```java
void add(E element)
```

Set等同于Collection接口， 不过其方法定义更加严格。

SortedSet和SortedMap接口会提供用于排序的比较器对象， 这两个接口定义了可以得到集合子集视图的方法

接口NavigableSet和NabigableMap中包含一些用于搜索和遍历有序集和映射的方法， TreeSet和TreeMap实现了这些接口

![image-20210609193454664](E:\学习笔记\java\java核心技术 第11版\image-20210609193454664.png)



## 链表

java中所有链表都是双向链接的

```java
var staff = new LinkedList<String>();
staff.add("Amy");
staff.add("Bob");
staff.add("Carl");
Iterator<String> iter = staff.iterator();
String first = iter.next();
String second = iter.next();
iter.remove();		//remove last visited element
```

集合类库提供ListIterator子接口， 包含add方法

```java
interface ListIterator<E> extends Iterator<E>
{
    void add(E element);
    ...
}
```

还有两个方法用来反向遍历链表

```java
E previous()
boolean hasPrevious()
```

声明迭代器如下：

```java
ListIterator<String> iter = staff.listIterator();
```



```java
var staff = new LinkedList<String>();
staff.add("Amy");
staff.add("Bob");
staff.add("Carl");
ListIterator<String> iter = staff.listIterator();
iter.next();
iter.add("Juliet");
```

set方法用一个新元素替换调用next或prevoius方法返回的上一个元素

```java
LIstIterator<String> iter = list.listIterator();
String oldValue = iter.next();
iter.set(newValue);
```

当一个迭代器发现其集合被另一个迭代器修改， 或该集合自身某个方法修改， 会抛出ConcurrentModificationException异常

```java
List<String> list = ...;
ListIterator<String> iter1 = list.listIterator();
LIstIterator<String> iter2 = list.listIterator();
iter1.next();
iter2.remove();
iter2.next();		//throws ConcurrentModificationException
```

有一种简单的方法检测并发修改：

集合可以跟踪更改操作的次数， 每个迭代器都会为它负责的更改操作维护一个单独的更改操作数。每个迭代器方法的开始处检查它自己的更改操作数是否和集合的更改操作数相等， 若不一致， 抛出一个ConcurrentModificationException

nextIndex和previousIndex方法返回元素的整数索引

```java
package linkedList;

import java.util.*;

/**
 * This program demonstrates operations on linked lists.
 * @author Cay Horstmann
 */

 public class LinkedListTest
 {
    public static void main(String[] args) {
        var a = new LinkedList<String>();
        a.add("Amy");
        a.add("Carl");
        a.add("Erica");

        var b = new LinkedList<String>();
        b.add("Bob");
        b.add("Doug");
        b.add("Frances");
        b.add("Gloria");

        //merge the words from b into a

        ListIterator<String> aIter = a.listIterator();
        Iterator<String> bIter = b.iterator();

        while (bIter.hasNext())
        {
            if(aIter.hasNext()) aIter.next();
            aIter.add(bIter.next());
        }

        System.out.println(a);

        //remove every second word from b

        bIter = b.iterator();

        while(bIter.hasNext())
        {
            bIter.next();
            if(bIter.hasNext())
            {
                bIter.next();
                bIter.remove();
            }
        }

        System.out.println(b);

        //bulk operation: remove all words in b from a
        a.removeAll(b);
        System.out.println(a);
    }
 }
```

### API

java.util.List< E >

* ```
  ListIterator<E>
  listIterator()
  ```

  Returns a list iterator over the elements in this list (in proper sequence).

* ```
  ListIterator<E>
  listIterator(int index)
  ```

  Returns a list iterator over the elements in this list (in proper sequence), starting at the specified position in the list.

* ```
  void
  add(int index, E element)
  ```

  Inserts the specified element at the specified position in this list (optional operation).

* ```
  boolean
  add(E e)
  ```

  Appends the specified element to the end of this list (optional operation).

* ```
  boolean
  addAll(int index, Collection<? extends E> c)
  ```

  Inserts all of the elements in the specified collection into this list at the specified position (optional operation).

* ```
  boolean
  addAll(Collection<? extends E> c)
  ```

  Appends all of the elements in the specified collection to the end of this list, in the order that they are returned by the specified collection's iterator (optional operation).

* ```
  boolean
  remove(Object o)
  ```

  Removes the first occurrence of the specified element from this list, if it is present (optional operation).

* ```
  E
  get(int index)
  ```

  Returns the element at the specified position in this list.

* ```
  E
  set(int index, E element)
  ```

  Replaces the element at the specified position in this list with the specified element (optional operation).

* ```
  int
  indexOf(Object o)
  ```

  Returns the index of the first occurrence of the specified element in this list, or -1 if this list does not contain the element.

* ```
  int
  lastIndexOf(Object o)
  ```

  Returns the index of the last occurrence of the specified element in this list, or -1 if this list does not contain the element.





java.util.ListIterator< E >

* ```java
  void 
  add(E e)
  ```

  Inserts the specified element into the list (optional operation).

* ```java
  boolean hasNext()
  ```

  Returns `true` if this list iterator has more elements when traversing the list in the forward direction.

* ```
  boolean
  hasPrevious()
  ```

  Returns `true` if this list iterator has more elements when traversing the list in the reverse direction.

* ```
  E
  next()
  ```

  Returns the next element in the list and advances the cursor position.

* ```
  int
  nextIndex()
  ```

  Returns the index of the element that would be returned by a subsequent call to [`next()`](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/util/ListIterator.html#next()).

* ```
  E
  previous()
  ```

  Returns the previous element in the list and moves the cursor position backwards.

* ```
  int
  previousIndex()
  ```

  Returns the index of the element that would be returned by a subsequent call to [`previous()`](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/util/ListIterator.html#previous()).

* ```
  void
  remove()
  ```

  Removes from the list the last element that was returned by [`next()`](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/util/ListIterator.html#next()) or [`previous()`](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/util/ListIterator.html#previous()) (optional operation).

* ```
  void
  set(E e)
  ```

  Replaces the last element returned by [`next()`](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/util/ListIterator.html#next()) or [`previous()`](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/util/ListIterator.html#previous()) with the specified element (optional operation).





java.util.LinkedList< E >

* ```
  LinkedList()
  ```

  Constructs an empty list.

* ```
  LinkedList(Collection<? extends E> c)
  ```

  Constructs a list containing the elements of the specified collection, in the order they are returned by the collection's iterator.

* ```
  void
  addFirst(E e)
  ```

  Inserts the specified element at the beginning of this list.

* ```
  void
  addLast(E e)
  ```

  Appends the specified element to the end of this list.

* ```
  E
  getFirst()
  ```

  Returns the first element in this list.

* ```
  E
  getLast()
  ```

  Returns the last element in this list.

* ```
  E
  removeFirst()
  ```

  Removes and returns the first element from this list.

* ```
  E
  removeLast()
  ```

  Removes and returns the last element from this list.





## 数组列表

ArrayList封装了一个动态再分配的数组

单线程时使用ArrayList， 多线程时使用Vector

## 散列集

散列表（hash table）用来快速查找对象， 散列表为每个对象计算一个整数称为散列码（hash code）

hashCode方法必须与equals方法兼容

通常将桶数设置为预计元素个数的75%-150%， 标准库默认类值是16

若散列表太满， 就需要再散列（rehashed）， 装填因子（load factor）默认为0.75.

HashSet类实现了基于散列表的集

```java
package set;

import java.util.*;

/**
 * This program uses a set to print all unique words in System.in.
 * @author Cat Horstmann
 */

public class SetTest 
{   
    public static void main(String[] args) {
        var words = new HashSet<String>();
        long totalTime = 0;

        try(var in = new Scanner(System.in))
        {
            while(in.hasNext())
            {
                String word = in.next();
                long callTime = System.currentTimeMillis();
                words.add(word);
                callTime = System.currentTimeMillis() - callTime;
                totalTime += callTime;
            }
        }

        Iterator<String> iter = words.iterator();
        for (int i = 1; i <= 20 && iter.hasNext(); i++) 
        {
            System.out.println(iter.next());
        }
        System.out.println("...");
        System.out.println(words.size() + " distinct words. " + totalTime + "milliseconds.");
    }
    
}
```



### API

java.util.HashSet< E >

* ```
  HashSet()
  ```

  Constructs a new, empty set; the backing `HashMap` instance has default initial capacity (16) and load factor (0.75).

* ```
  HashSet(int initialCapacity)
  ```

  Constructs a new, empty set; the backing `HashMap` instance has the specified initial capacity and default load factor (0.75).

* ```
  HashSet(int initialCapacity, float loadFactor)
  ```

  Constructs a new, empty set; the backing `HashMap` instance has the specified initial capacity and the specified load factor.

* ```
  HashSet(Collection<? extends E> c)
  ```

  Constructs a new set containing the elements in the specified collection.





java.lang.Object

* ```
  int
  hashCode()
  ```

  Returns a hash code value for the object.



## 树集

树集与散列集十分类似， 不过树集是一个有序集合（sorted collection）, 当前实现使用的是**红黑树（red-black tree）**

[^1]: 要使用树集， 必能够比较元素， 这些元素必须实现Comparable接口或者构造集时提供一个Comparator 
[^2]: TreeSet类实现了NavigableSet接口， 该接口增加了几个查找元素以及反向遍历的便捷方法



treeSet/TreeSetTest.java

```java
package treeSet;
import java.util.*;

/**
 * This program sorts a set of Item objects by comparing their descriptions.
 * @author Cay Horstmann
 */


public class TreeSetTest 
{
    public static void main(String[] args) {
        var parts = new TreeSet<Item>();
        parts.add(new Item("Toaster", 1234));
        parts.add(new Item("Widget", 4562));
        parts.add(new Item("Modem", 9912));
        System.out.println(parts);

        var sortByDescription = new TreeSet<Item>(Comparator.comparing(Item::getDescription));

        sortByDescription.addAll(parts);
        System.out.println(sortByDescription);
    }
}
```



treeSet/Item.java

```java
package treeSet;

import java.util.*;

/**
 * An item with a description and a part number.
 */

public class Item implements Comparable<Item>
{
    private String description;
    private int partNumber;

    /**
     * Constructs an item.
     * @param aDescription the item's description
     * @param aPartNumber the item's part number
     */
    public Item(String aDescription, int aPartNumber)
    {
        description = aDescription;
        partNumber = aPartNumber;
    }

    /**
     * Gets the description of this item.
     * @return the description
     */

    public String getDescription() {
        return description;
    }
    @Override
    public String toString() {
        return "[description=" + description + ", partNumber=" + partNumber + "]";
    }
    @Override
    public boolean equals(Object otherObject) {
        if(this == otherObject) return true;
        if(otherObject == null) return false;
        if(getClass() != otherObject.getClass())   return false;
        var other = (Item)otherObject;
        return Objects.equals(description, other.description) && partNumber == other.partNumber;
    }
    @Override
    public int hashCode() {
        return Objects.hash(description, partNumber);
    }
    @Override
    public int compareTo(Item other) 
    {
        int diff = Integer.compare(partNumber, other.partNumber);
        return diff!= 0 ? diff : description.compareTo(other.description);
        
    }
}
```



### API

java.util.TreeSet< E >

* ```
  TreeSet()
  ```

  Constructs a new, empty tree set, sorted according to the natural ordering of its elements.

* ```
  TreeSet(Collection<? extends E> c)
  ```

  Constructs a new tree set containing the elements in the specified collection, sorted according to the *natural ordering* of its elements.

* ```
  TreeSet(Comparator<? super E> comparator)
  ```

  Constructs a new, empty tree set, sorted according to the specified comparator.

* ```
  TreeSet(SortedSet<E> s)
  ```

  Constructs a new tree set containing the same elements and using the same ordering as the specified sorted set.





java.util.SortedSet< E >

* ```
  Comparator<? super E>
  comparator()
  ```

  Returns the comparator used to order the elements in this set, or `null` if this set uses the [natural ordering](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/lang/Comparable.html) of its elements.

* ```
  E
  first()
  ```

  Returns the first (lowest) element currently in this set.

* ```
  E
  last()
  ```

  Returns the last (highest) element currently in this set.

  



java.util.NavigableSet < E >

* ```
  E
  higher(E e)
  ```

  Returns the least element in this set strictly greater than the given element, or `null` if there is no such element.

* ```
  E
  lower(E e)
  ```

  Returns the greatest element in this set strictly less than the given element, or `null` if there is no such element.

* ```
  E
  ceiling(E e)
  ```

  Returns the least element in this set greater than or equal to the given element, or `null` if there is no such element.

* ```
  E
  floor(E e)
  ```

  Returns the greatest element in this set less than or equal to the given element, or `null` if there is no such element.

* ```
  E
  pollFirst()
  ```

  Retrieves and removes the first (lowest) element, or returns `null` if this set is empty.

* ```
  E
  pollLast()
  ```

  Retrieves and removes the last (highest) element, or returns `null` if this set is empty.

* ```
  Iterator<E>
  descendingIterator()
  ```

  Returns an iterator over the elements in this set, in descending order.

## 队列与双端队列

双端队列（deque）允许在头部和尾部都高效地添加元素， ArrayDequeue和LinkedList都实现了Deque, 使用这两个类可以实现双端队列

### API

java.util.Queue< E >

* ```
  boolean
  add(E e)
  ```

  Inserts the specified element into this queue if it is possible to do so immediately without violating capacity restrictions, returning `true` upon success and throwing an `IllegalStateException` if no space is currently available.

* ```
  boolean
  offer(E e)
  ```

  Inserts the specified element into this queue if it is possible to do so immediately without violating capacity restrictions.

* ```
  E
  remove()
  ```

  Retrieves and removes the head of this queue.

* ```
  E
  poll()
  ```

  Retrieves and removes the head of this queue, or returns `null` if this queue is empty.

* ```
  E
  element()
  ```

  Retrieves, but does not remove, the head of this queue.

* ```
  E
  peek()
  ```

  Retrieves, but does not remove, the head of this queue, or returns `null` if this queue is empty.



java.util.Deque< E > 

* ```
  void
  addFirst(E e)
  ```

  Inserts the specified element at the front of this deque if it is possible to do so immediately without violating capacity restrictions, throwing an `IllegalStateException` if no space is currently available.

* ```
  void
  addLast(E e)
  ```

  Inserts the specified element at the end of this deque if it is possible to do so immediately without violating capacity restrictions, throwing an `IllegalStateException` if no space is currently available.

* ```
  boolean
  offerFirst(E e)
  ```

  Inserts the specified element at the front of this deque unless it would violate capacity restrictions.

* ```
  boolean
  offerLast(E e)
  ```

  Inserts the specified element at the end of this deque unless it would violate capacity restrictions.

* ```
  E
  removeFirst()
  ```

  Retrieves and removes the first element of this deque.

* ```
  E
  removeLast()
  ```

  Retrieves and removes the last element of this deque.

* ```
  E
  pollFirst()
  ```

  Retrieves and removes the first element of this deque, or returns `null` if this deque is empty.

* ```
  E
  pollLast()
  ```

  Retrieves and removes the last element of this deque, or returns `null` if this deque is empty.

* ```
  E
  getFirst()
  ```

  Retrieves, but does not remove, the first element of this deque.

* ```
  E
  getLast()
  ```

  Retrieves, but does not remove, the last element of this deque.

* ```
  E
  peekFirst()
  ```

  Retrieves, but does not remove, the first element of this deque, or returns `null` if this deque is empty.

* ```
  E
  peekLast()
  ```

  Retrieves, but does not remove, the last element of this deque, or returns `null` if this deque is empty.



java.util.ArrayDeque< E >

* ```
  ArrayDeque()
  ```

  Constructs an empty array deque with an initial capacity sufficient to hold 16 elements.

* ```
  ArrayDeque(int numElements)
  ```

  Constructs an empty array deque with an initial capacity sufficient to hold the specified number of elements.

## 优先队列

优先队列( priority queue)中的元素可以按照任意的顺序插入， 但对按照有序的顺序进行检索。

因为优先队列使用了堆(heap)的数据结构， 堆是一个可以自组织的二叉树， 若母节点的值恒小于子节点， 称为最小堆， 反之称为最大堆

```java
package priorityQueue;

import java.util.*;


import java.time.*;

/**
 * This program demonstrates the use of a priority queue.
 * @author Cay Horstmann
 */

public class PriorityQueueTest
{
    public static void main(String[] args) {
        var pq = new PriorityQueue<LocalDate>();
        pq.add(LocalDate.of(1906, 12, 9));      //G.Hopper
        pq.add(LocalDate.of(1815, 12, 10));
        pq.add(LocalDate.of(1903, 12, 3));
        pq.add(LocalDate.of(1910, 6, 22));
        System.out.println("Iterating over elements...");
        for (LocalDate date : pq) 
            System.out.println(date);
        System.out.println("Removing elements...");
        while(!pq.isEmpty())
        System.out.println(pq.remove());
    }
}
```





### API

java.util.PriorityQueue

* ```java
  PriorityQueue()
  ```

  构造一个空的优先队列(容量默认11)

  ```java
  PriorityQueue(int initialCapacity)
  ```

  构造一个具有指定容量的优先队列

*  ```java
   PriorityQueue(int initialCapacity, Comparator<? super E> c)
   ```

  构造一个使用指定比较器的优先队列





# 映射

## 基本映射操作

 

如果不需要按照有序的顺序访问键， 散列映射相对更快

size方法返回映射中的元素数， 可以用lambda表达式对映射进行迭代处理

```java
score.forEach(k, v) ->
    System.out.println("key=" + K + ", value=" + v);
```

```java
package map;
import java.util.*;

/**
 * This program demonstrates the use of a map with key type String and value type Employee.
 * @author Cay Horstmann
 */


public class MapTest
{
    public static void main(String[] args)
    {
        var staff = new HashMap<String, Employee>();
        staff.put("144-25-5464", new Employee("Amy Lee"));
        staff.put("567-24-2546", new Employee("Harry Hacker"));
        staff.put("157-62-7935", new Employee("Gary Cooper"));
        staff.put("456-62-5527", new Employee("Francesca Cruz"));

        //print all entries

        System.out.println(staff);
        //remove an entry
        staff.remove("567-24-2546");

        //replace an entry
        staff.put("456-62-5527", new Employee("Francesca Miller"));

        //look up a value
        System.out.println(staff.get("157-62-7935"));

        // iterate through all entries
        staff.forEach((k, v) ->
        System.out.println("key=" + k + ", value=" + v));
    }

}
```

### API

java.util.Map<K, V>

* ```
  V
  get(Object key)
  ```

  Returns the value to which the specified key is mapped, or `null` if this map contains no mapping for the key.

* ```
  default V
  getOrDefault(Object key, V defaultValue)
  ```

  Returns the value to which the specified key is mapped, or `defaultValue` if this map contains no mapping for the key.

* ```
  V
  put(K key, V value)
  ```

  Associates the specified value with the specified key in this map (optional operation).

* ```
  void
  putAll(Map<? extends K,? extends V> m)
  ```

  Copies all of the mappings from the specified map to this map (optional operation).

* ```
  boolean
  containsKey(Object key)
  ```

  Returns `true` if this map contains a mapping for the specified key.

* ```
  boolean
  containsValue(Object value)
  ```

  Returns `true` if this map maps one or more keys to the specified value.

* ```
  default void
  forEach(BiConsumer<? super K,? super V> action)
  ```

  Performs the given action for each entry in this map until all entries have been processed or the action throws an exception.

  



java.util.HashMap< K,  V >

* 

  ```
  HashMap()
  ```

  Constructs an empty `HashMap` with the default initial capacity (16) and the default load factor (0.75).

* 

  ```
  HashMap(int initialCapacity)
  ```

  Constructs an empty `HashMap` with the specified initial capacity and the default load factor (0.75).

* 

  ```
  HashMap(int initialCapacity, float loadFactor)
  ```

  Constructs an empty `HashMap` with the specified initial capacity and load factor.



java.util.TreeMap< K, V >

* ```
  TreeMap()
  ```

  Constructs a new, empty tree map, using the natural ordering of its keys.

  ```
  TreeMap(Comparator<? super K> comparator)
  ```

  Constructs a new, empty tree map, ordered according to the given comparator.

  ```
  TreeMap(Map<? extends K,? extends V> m)
  ```

  Constructs a new tree map containing the same mappings as the given map, ordered according to the *natural ordering* of its keys.

  ```
  TreeMap(SortedMap<K,? extends V> m)
  ```

  Constructs a new tree map containing the same mappings and using the same ordering as the specified sorted map.





java.util. SortedMap< K, V>

* ```
  Comparator<? super K>
  comparator()
  ```

  Returns the comparator used to order the keys in this map, or `null` if this map uses the [natural ordering](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/lang/Comparable.html) of its keys.

* ```
  K
  firstKey()
  ```

  Returns the first (lowest) key currently in this map.

* ```
  K
  lastKey()
  ```

  Returns the last (highest) key currently in this map.



## 更新映射条目

更新映射有如下方式：

```java
counts.put(word, counts.get(word) + 1);
```

但是第一次见到word时会有问题

```java
counts.put(word, counts.getOrDefaule(word, 0) + 1);
```



另一种方法是使用putIfAbsent

```java
counts.putIfAbsent(word, 0);
counts.put(word, counts.get(word) + 1);
```



merge方法更为方便

```java
counts.merge(word, 1, Integer::sum);
```



## 映射视图

可以得到映射的视图（view）

```java
Set< K > KeySet();
Collection< V > values();
Set< Map.Entry< K, V > > entrySet();
```

分别返回键集合， 值集合， 键值对集合

Set接口扩展了Collection接口

```java
Set< String > keys = map.keySet();
for (String key: keys)
{
    do something with key
}
```

若想同时查看键和值

```java
for (Map.Entry< String, Employee> entry : staff.entrySet())
{
    String k = entry.getKey();
    Empolyee v = entry.getValue();
    do something with key, value
}
```



```java
for (var entry: map.entrySet())
{
    do something with entry.getKey(), entry.getValue()
}
```

现在只需要使用forEach方法

```java
map.forEach((k, v) -> {
    do something with k, v
});
```

键集视图可以调用迭代器的remove方法， 但不能进行添加， 映射条目集视图同样



## 弱散列映射



当对键的最后一个引用都没有时（此时对键的唯一引用来自于散列表映射条目时）， WeakHashMap类可以与垃圾回收器一起删除键值对

WeakHashMap类使用弱引用(weak references)保存键

如果某个对象没有被他人再引用时， 垃圾回收器会将其回收

如果某个对象只由WeakReference引用时， 垃圾回收也会将其回收， 其将会将该对象的一个弱引用加入队列， WeakHashMap检查队列， 删除相关联的映射条目

## 链接散列集和映射

LinkedHashMap和LinkedHashSet 由双向链表实现， 会记住插入元素项的顺序（TreeSet使用的是大小顺序， HashSet使用随机顺序）。

连接散列映射使用访问顺序来迭代处理映射条目

每次使用get或put时会将项放到链表的尾部

构造散列映射使用

```java
LinkedHashMap< K, V > (initialCapacity, loadFactor, true)
```

**作为一般规则，默认负载因子（0.75）在时间和空间成本上提供了很好的折衷。较高的值会降低空间开销，但提高查找成本（体现在大多数的HashMap类的操作，包括get和put）。设置初始大小时，应该考虑预计的entry数在map及其负载系数，并且尽量减少rehash操作的次数。如果初始容量大于最大条目数除以负载因子，rehash操作将不会发生。**



当在表中找不到元素项且表相当满时， 可以得到表的一个迭代器， 删除其枚举的前几个项， 这些项会是近期最少使用的几个元素。

可以通过构造子类， 覆盖方法来实现自动化

```java
protected boolean removeEldestEntry(Map.Entry<K, V> eldest)
```



```java
var cache = new LinkedHashMap<K, V>(128, 0.75F,true)
{
    protected boolean removeEldestEntry(Map.entry<K, V> eldest)
    {
        return size() > 100;
    }
}
```

当方法返回true时， 添加一个新映射条目将会删除eldest项



## 枚举集与映射

EnumSet是枚举类型元素集的高效实现， EnumSet内部使用位序列实现， 若对应的值在集中， 相应的位被设置为1

EnumSet使用静态工厂方法构造

```java
        enum Weekday {MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY};
        EnumSet<Weekday> always = EnumSet.allof(Weekday.class);
        EnumSet<Weekday> never = EnumSet.noneOf(Weekday.class);
        EnumSet<Weekday> workday = EnumSet.range(Weekday.MONDAY, Weekday.FRIDAY);
        EnumSet<Weekday> mwf = EnumSet.of(Weekday.MONDAY, Weekday.WEDNESDAY, Weekday.FRIDAY);
```

可以使用set'常用接口来修改EnumSet

EnumMap是一个键类型位枚举类型的映射， 直接且高效地实现为一个值数组。需要在构造器中指定键类型

```java
var personInCharge = new EnumMap<Weekday, Employee>(Weekday.class);
```

## 表示散列映射

IdentityHashMap类中， 键的散列值使用System.identityHashCode计算， 这是Object.hashCode的计算方法

IdentityHashMap类使用==进行比较, 而不是equals



# 视图与包装器

keySet方法返回一个 实现了Set接口的类对象, 由这个类的方法操纵原映射

## 小集合



```java
List<String> names =  List.of("Peter", "Paul", "Mary");
Set<Integer> numbers = Set.of(2, 3, 5);
```

对于映射

```java
Map<String, Integer> scores = Map.of("Peter", 2, "Paul", 3, "Mary", 5);
```

元素, 键或值不能为null

对于Map接口, 无法提供参数可变的of方法版本, 因为参数类型会在键和值类型之间交替

不过其ofEntries静态方法可以实现

```java
import static java.util.Map.*;
...
Map<String, Integer> scores = ofentries(
	entry("Peter", 2), 
	entry("Paul", 3),
	entry("Mary", 5));
```

**of或ofEntries方法生成的集合对象无法更改**

```java
var names = new ArrayList<>(List.of("Peter", "Paul", "Mary"));
```

方法调用

```java
Collections.nCopies(n, anObject)
```

会返回一个实现了List接口的不可变对象

```java 
List<String> settings = Collections.nCopies(100, "DEFAULT");
```

## 子范围

若想取出第10到第19个元素

```java
List<Employee> group2 = staff.subList(10, 20);
```

该方法与String类的substring方法参数情况相同。

对子范围操作会自动反映到整个列表。

对于有序集和映射， 可以适应排序顺序建立子范围

```java
SortedSet<E> subSet(E from, E to);
SortedSet<E> headSet(E to);
SortedSet<E> tailSet(E from);
```

```java
SortedMap<K, V> subMap(K from, K to);
SortedMap<K, V> headMap(K to);
SortedMap<K, v> tailMap(K from);
```

java6引入的NavigableSet接口允许更多地控制子范围操作， 包括指定是否包括边界

```java
NavigableSet<E> subSet(E from, boolean fromInclusive,E to, boolean toInclusive);
NavigableSet<E> headSet(E to, boolean toInclusive);
NavigableSet<E> tailSet(E from, boolean fromInclusive);
```

## 不可修改的视图



Collections类中由生成不可改变视图的几个方法（unmodifiable view）。

使用如下8个方法来获得不可修改视图

```java
Collections.unmodifiableCollection;
Collections.unmodifiableList;
Collections.unmodifiableSet;
Collections.unmodifiableSortedSet;
Collections.unmodifiableNavigableSet;
Collections.unmodifiableMap;
Collections.unmodifiableSortedMap;
Collections.unmodifiableNavigableMap;
```

```java
var staff = new LinkedList<String>();
...
lookAt(Collections.unmodifiableList(staff));
```





## 同步视图

视图机制确保了常规集合是线程安全的， 而没有实现线程安全的集合类

Collections类的静态synchronizedMap方法可以将任何一个映射转换为有同步访问方法的Map

```java
var map = Collections.synchronizedMap(new HashMap< String, Emloyee >());
```



## 检查型视图

```java
var strings = new ArrayList<String>();
ArrayList rawList = strings;			//warning only, not an error,
										//for conpatibility with legacy code
rawList.add(new Date());				//now strings contains a Date object!
```

只有当调用get时， 会出现报错。

检查型视图可以检测该类问题

```java
List<String> safeStrings = Collections.checkedList(strings, String.class);
```

# 算法

## 泛型算法

找出数组中最大元素：

```java
if(a.length == 0) throw new NoSuchElementException();
T largest = a[0];
for (int i = 1; i < a.length; i++)
    if(largest.compareTo(a[i]) < 0)
        largest = a[i];
```

数组列表最大元素：

```java
if(v.size() == 0) throw new NoSuchElementException();
T largest = v.get(0);
for(int i = 1; i < v.size(); i++)
    if(largest.compareTo(v.get(i)) < 0)
        largest = v.get(i);
```

链表：

```java
if (l.isEmpty()) throw new NoSuchElementException();
Iterator<T> iter = l.iterator();
T.largest = iter.next();
while(iter.hasNext())
{
    T next = iter.next();
    if(largest.compareTo(next) < 0)
        largest = next;
}
```

泛型算法：

```java
public static <T extends Comparable> T max(Collection<T> c)
    {
        if(c.isEmpty()) throw new NoSuchElementException();
        Iterator<T> iter = c.iterator();
        T largest = iter.next();
        while(iter.hasNext())
        {
            T next = iter.next();
            if(largest.compareTo(next) < 0)
                largest = next;
        }
        return largest;
    }
```

## 排序和混排

Collections类中sort方法可以对实现了List接口的集合进行排序

```java
var staff = new LinkedList<String>();
...
Collections.sort(staff);
```

该调用默认使用默认比较器

使用List接口的sort方法并传入一个Comparator对象,可采用其他原则排序

```java
staff.sort(Comparator.comparingDouble(Employee::getSalary));
```

降序排序：

```java
staff.sort(Comparator.reverseOrder())
```

```java
staff.sort(Comparator.comparingDouble(Employee::getSalary).reversed())
```

Collections类中shuffle算法实现随机混排。



```java
package shuffle;

import java.util.*;

/**
 * This program demonstrates the random shuffle and sort algorithms.
 * @author Cay Horstmann
 */
public class ShuffleTest
{
    public static void main(String[] args) {
        var numbers = new ArrayList<Integer>();
        for (int i = 1; i <= 49 ; i++)
        {
            numbers.add(i);
        }
        Collections.shuffle(numbers);
        List<Integer> winningCombination = numbers.subList(0, 6);
        
        System.out.println(numbers);
        Collections.sort(winningCombination);
        System.out.println(winningCombination);
        System.out.println(numbers);
    }
}

```



## 二分查找

Collections类实现了binarySearch方法

前提： 集合必须有序

```java
i = Collections.binarySearch(c, element);
i = Collections.binarySearch(c, element, comparator);
```



## 简单算法

```java
Collections.replaceAll(words, "C++", "Java");
```

等于以下方法

```java
for (int i = 0; i < words.size(); i++)
    if(words.get(i).equals("C++")) words.set(i, "java");
```

Collection.removeIf和List.replaceAll需要提供一个lambda表达式来测试或转换元素

```java
words.removeIf(w -> w.length() <= 3);
words.replaceAll(String.toLowerCase);
```



## 批操作

从coll1中删除coll2的元素

```java
coll1.removeAll(coll2);
```

找出交集：

```java
var result = new HashSet<String>(firstSet);
result.retainAll(secondSet);
```



```java
staff.subList(0, 10),clear();
```



## 集合和数组间的转换

```java
String [] values = ...;
var staff = new HashSet<>(List.of(values));
```

集合到数组有些困难

```java
Object[] values = staff.toArray();	//toArray方法创建Object[]数组， 不能强制类型转换
String[] values = staff.toArray(new String[0]);	//返回的数组创建相同数据类型
staff.toArray(new String[staff.size()]);		//在这种情况下不会创建新数组
```

# 遗留的集合

## Hashtable类

Hashtable和HashMap一样

## 枚举

遗留的集合使用Enumeration接口遍历元素序列， 实现的两个方法为hasMoreElements 和nextElement

可以使用Collections.list将元素收集到一个ArrayList中

```java
ArrayList<String> loggerNames = Collections.list(LogManager.getLoggerNames());
```

静态方法Collections.enumeration产生枚举对象

```java
List<InputStream> streams = ...;
var in = new SequenceInputStream(Collections.enumeration(stream));
```



## 属性映射

属性映射(property map)是一个特殊类型的映射结构

1. 键和值都是字符串
2. 映射可以很容易保存到文件以及从文件加载
3. 有一个二级表存放默认值

实现类名为Properties

对于指定程序的配置选项很有用

```java
var settings = new Properties();
setting.setProperty("width", "600.0");
setting.setProperty("filename", "home/cay/books/cj11/code/v1ch11/raven.html");
```

使用store方法保存到文件

```java
var out = new FileOutputStream("program.properies");
setting.store(out, "Program Properties");
```

加载使用如下调用

```java
var in = new FileInputStream("program.properties");
setting.load(in);
```

System.getProperties方法生成Properties对象描述信息

getProperty方法1生成描述的字符串

```java
String userDir = System.getProperty("user.home");
```

如下调用当键不存在时自动设置为相应的字符串

```java
String filename = setting.getProperty("filename", "");
```

可以将所有默认值放在一个二级属性映射中， 并在主属性映射构造器中提供该二级映射。

```java
var defaultSettings = new Properties();
defaultSettings.setProperty("width", "600");
defaultSettings.setProperty("height", "400");
dafaultSettings.setProperty("filename", "");
...
var settings = new Properties(dafaultSettings);
```

## 栈

Stack类有push方法和pop方法与peek方法



## 位集

BitSet类用于存储一个位序列

位集将位包装在字节中， 使用位集比使用Boolean对象的ArrayList更高效

```java
package sieve;

import java.util.BitSet;

/**
 * This program runs the Sieve of Erathostenes benchmark. It computes all primes
 * up to 2,000,000
 * @author Cay Horstmann
 */
public class Sieve
{
    public static void main(String[] args) {
        int n = 2000000;
        long start = System.currentTimeMillis();
        var bitSet = new BitSet(n + 1);
        int count = 0;
        int i;
        for (i = 2; i <= n; i++)
        {
            bitSet.set(i);
        }
        i = 2;
        while(i * i <= n)
        {
            if(bitSet.get(i))
            {
                count++;
                int k = 2 * i;
                while(k <= n)
                {
                    bitSet.clear(k);
                    k += i;
                }
            }
            i++;
        }
        while(i <= n)
        {
            if(bitSet.get(i)) count++;
            i++;
        }
        long end = System.currentTimeMillis() ;
        System.out.println(count + "primes");
        System.out.println((end - start) + "milliseconds");
    }
}
```



```cpp
/**
 *@author Cay Horstmann
 */
#include <bitset>
#include <iostream>
#include <ctime>

using namespace std;

int main()
{
	const int N = 2000000;
	clock_t cstart = clock();
	bitset<N + 1> b;
	int count = 0;
	int i;
	for (i = 2; i <= N; i++)
		b.set(i);
	i = 2;
	while (i * i <= N)
	{
		if (b.test(i))
		{
			count++;
			int k = 2 * i;
			while (k <= N)
			{
				b.reset(k);
				k += i;
			}
		}
		i++;
	}
	while (i <= N)
	{
		if (b.test(i))
			count++;
		i++;
	}
	clock_t cend = clock();
	double millis = 1000.0 * (cend - cstart) / CLOCKS_PER_SEC;
	cout << count << "primes\n" << millis << "milliseconds\n";
	return 0;
}
```

















