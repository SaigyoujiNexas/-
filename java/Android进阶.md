# HashMap

## put是如何实现的

### key和value的分工

transient 关键字让类序列化时不存入该字段。

```java
public class HashMap<K, V> extends AbstractMap<K, V> implements Map<K, V>, Cloneable, Serializable{
    ...
    transient HashMapEntry<K, V>[] table = (HashMapEntry<K, V>[]) EMPTY_TABLE; 
    static class HashMapEntry<K, V> implements Map.Entry<K, V>{
        final K key;
        V value;
        int hahs;
        HashMapEntry<K, V> next;
        
        /**
        * Creates new entry.
        */
        HashMapEntry(int h, K k, V v, HashMapEntry<K, V> n){
            value = v;
            next = n;
            key = k;
            hash = h;
        }
        public final K getKey(){
            return key;
        }
        public final V getValue(){
            return value;
        }
        public final V setValue(V newValue){
            V oldValue = value;
            value = newValue;
            return oldValue;
        }
        public fianl boolean equals(Object o){
            if(!(o instanceof Map.entry))
                return false;
            Map.Entry e = (Map.Entry) o;
            Object k1 = getKey();
            Object k2 = e.getKey();
            
            if(k1 == k2 || (k1 != null && k1.equals(k2)))
                return true;
        }
    }
}
```

