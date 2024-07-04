# 从迭代到流的操作

``` java
var contents = new String(Files.readAllBytes(Path.get("alice.txt")), StandardCharsets.UTF_8);
List<String> words = List.of(contents.split("\\PL+"));
int count = 0;
for (String w: words){
    if(w.length() > 12) count++;
}
```

使用流时相同的操作如下所示

```java
long count = words.stream().filter(w->w.length() > 12).count();
```





```java
package streams;

import java.io.*;
import java.nio.file.*;
import java.util.*;

/**
 * @version 1.02 2019-08-28
 * @author Cay Horstmann
 */
public class CountLongWords
{
   public static void main(String[] args) throws IOException
   {
      var contents = Files.readString(
         Paths.get("../gutenberg/alice30.txt"));
      List<String> words = List.of(contents.split("\\PL+"));

      long count = 0;
      for (String w : words)
      {
         if (w.length() > 12) count++;
      }
      System.out.println(count);

      count = words.stream().filter(w -> w.length() > 12).count();
      System.out.println(count);

      count = words.parallelStream().filter(w -> w.length() > 12).count();
      System.out.println(count);
   }
}
```



# 流的创建

使用Collection接口的steam方法可以将任何集合转化为流

数组可以使用静态方法Stream.of

```java
Stream<String> words = Stream.of(contents.split("\\PL+"));
```

使用Array.stream(array, from, to)可以用数组的一部分元素来创建一个流

Stream接口有两个创建无限流的静态方法

```java
Stream<String> echos = Stream.generate(() -> "Echo");
Stream<Double> randoms = Stream.generate(Math::random);
```

或

```java
Stream<BigInteger> integers = Stream.iterate(BigInteger.ZERO, n -> n.add(BigInteger.ONE));
```

要产生有限数列

```java
var limit = new BigInteger ("10000000");
Stream<BigInteger> integers
    = Stream.iterate(BigInteger.ZERO, 
                    n -> n.compareTo(limit) < 0, 
                    n -> n.add(BigInteger.ONE));
```

Stream.ofNullable 方法会用对象生成一个很短的流， 对象为null则长度为0， 否则长度为1

```java
package streams;

/**
 * @author Cay Horstmann
 */

import java.io.IOException;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import java.util.regex.Pattern;
import java.util.stream.*;

public class CreatingStreams
{
    public static <T> void show(String title, Stream<T> stream)
    {
        final int SIZE = 10;
        List<T> firstElements = stream.limit(SIZE + 1).collect(Collectors.toList());
        System.out.println(title + ": ");
        for(int i = 0; i < firstElements.size(); i++)
        {
            if( i > 0) System.out.print(", ");
            if(i < SIZE) System.out.print(firstElements.get(i));
            else System.out.print("...");
        }
        System.out.println();
    }

    public static void main(String[] args) throws IOException{
        Path path = Path.of("../gutenberg/alice30.txt");
        var contents = Files.readString(path);

        Stream<String> words = Stream.of(contents.split("\\PL+"));
        show("words", words);
        Stream<String> song = Stream.of("gently", "down", "the", "stream");
        show("song", song);
        Stream<String> silence = Stream.empty();
        show("silence", silence);

        Stream<String> echos = Stream.generate(() -> "Echo");
        show("echos", echos);

        Stream<Double> randoms = Stream.generate(Math::random);
        show("randoms", randoms);

        Stream<BigInteger> integers = Stream.iterate(BigInteger.ONE, n -> n.add(BigInteger.ONE));
        show("integers", integers);

        Stream<String> wordsAnotherWay = Pattern.compile("\\PL+").splitAsStream(contents);
        show("wordsAnotherWay", wordsAnotherWay);

        try(Stream<String> lines = Files.lines(path, StandardCharsets.UTF_8))
        {
            show("lines", lines);
        }
        Iterable<Path> iterable = FileSystems.getDefault().getRootDirectories();
        Stream<Path> rootDirectories = StreamSupport.stream(iterable.spliterator(), false);
        show("rootDirectories", rootDirectories);

        Iterator<Path> iterator = Paths.get("/usr/share/dict/words").iterator();
        Stream<Path> pathComponents = StreamSupport.stream(Spliterators.spliteratorUnknownSize(iterator,Spliterator.ORDERED), false);
        show("pathComponents", pathComponents);
    }
}
```

# filter, map 和 flatMap方法



流的转换会产生一个新的流， 它的元素派生自另一个流中的元素

```java
Stream<String> lowercaseWords = words.stream().map(String::toLowerCase);
```

将字符串转换为字符串流：

```java
public static Stream<String> codePoints(String s)
{
    var result = new ArrayList<String>();
    int i = 0;
    while (i < s.length())
    {
        int j = s.offsetByCodePoints(i, 1);
        result.add(s.subString(i, j));
        i = j;
    }
    return result.stream();
}
```

# 抽取子流和组合流

 调用stream.limit（n）会返回一个n个元素的流

```java
Stream<Double> randoms = Stream.generate(Math::random).limit(100);
```

stream.skip(n)方法丢弃前n个元素

stream.takeWhile(predicate)会在谓词为真时获取流中的所有元素， 然后停止

dropWhile方法做法相反

静态concat方法将两个流连接起来

# 其他的流转换

distinct方法会返回一个流， 元素从原有流产生， 剔除重复元素

对于流的排序， 有多种sorted方法可以使用

```java
Stream<String> longestFirst = words.stream().sorted(Comparator.comparing(String::length).reversed());
```





peek方法会产生另一个流， 每次获取一个元素时， 都会调用一个函数

```java
Object[] powers = Stream.iterate(1.0, p -> p * 2).peek(e -> System.out.println("Fetching" + e)).limit(20).toArray();
```



# 简单约简 

约简是一种**终结操作（terminal operation）**将流约简为可以在程序中使用的非流值

max和min方法返回一个Optional< T >的值。

```java
Optional<String> largest = words.max(String::compareToIgnoreCase);
System.out.println("largest: " + largest.orElse(""));
```

findFirst返回非空集合的第一个值

```java
Optional<String> startsWithQ = words.filter(s -> s.startsWith("Q")).findFirst();
```

findAny在并行处理时很好用

```java
Optional<String> startsWithQ = words.parallel().filter(s -> s.startsWith("Q")).findAny();
```

想知道是否存在匹配， 使用anyMatch

```java
boolean aWordStartsWithQ
    = words.parallel().anyMatch(s -> s.startsWith("Q"));
```

还有allMatch和noneMatch方法。

# Optional 类型

Optional< T >对象是一种包装器对象， 要么包装类型T对象， 要么没有包装任何对象

## 获取Optional值

```java
String result = optionalString.orElse("");
```

调用代码计算默认值：

```java
String result = optionalString.orElseGet(() -> System.getProperty("myapp.default"));
```

或抛出异常

```java
String result = optionalString.orElseThrow(IllegalStateException::new);
	//Supply a method that yields an exeception object
```

## 消费Optional值

ifPresent方法会接受一个函数， 如果该值存在， 那么它就会被传递给该函数， 否则什么都不发生。

```java
optionalValue.ifPresent(v -> Process v)
```

```java
optionalValue.ifPresentOrElse(
v -> System.out.println("Found" + v), () -> logger.warning("No match"));
```



## 管道化Optional值

可以使用filter方法来只处理那些在转换它之前或之后满足某种特定属性的Optional值， 如果不满足该属性， 那么管道产生空的结果

```java
Optional<String> transformed = optionalString
    .filter(s-> s.length() >= 8)
    .map(String::toUpperCase);
```

or方法可以将空optional替换为一个可替代的Optional

```java
Optional<String> result = optionalString.or(() ->
                                           alternatives.stream().findFirst());
```



## 不适合使用Optional值的方式

get方法在不存在Optional值情况下， 会抛出一个NoSuchElementException异常。

```java
Optional<T> optionalValue = ...;
optionalValue.get().somemethod();
```

并不安全

isPresent方法并不比

```java
if(value != null) value.someMethod();
```

更容易处理

1. optional类型的变量永远都不应该为null
2. 不要使用optional类型的域
3. 不要在集合中放置optional对象

## 创建Optioal值

Optional.of(result)和 Optioal.empty（）都可以用来创建

```java
public static Optional<Double> inverse(Double x)
{
    return x == 0 ? Optional.empty() : Optional.of(1 / x);
}
```

ofNullable方法被用来作为可能出现的null值和可选值之间的桥梁。Optional.ofNullable(obj)会在obj不为null情况下返回Optional.of(obj), 否则返回Optional.empty().

## 用flatMap构建Optional值的函数

假设有一个可以产生Optional< T >对象的方法f， 并且目标类型T具有一个可以产生Optional< U >的对象的方法g， 那么可以调用s.f().g()

但是这种组合无法工作， 因为s.f()的类型为Optional<T>, 而不是T

```java
Optional <U> result = s.f().flatMap(T::g);
```



```java
public static Optional<Double> squareRoot(Double x)
{
    return x < 0 ? Optional.empty() : Optional.of(Math::sqrt(x));
}
```

计算倒数的平方根： 

```java
Optional <Double> result = inverse(x).flatMap(MyMath::squareRoot);
```

或

```java
Optional<Double> result = Optional.of(-4.0).flatMap(Demo::inverse).flatMap(Demo::squareRoot);
```

## Optional转换为流

假设有一个用户ID流和一个方法： 

```java
Optional <User> lookup(String id);
```

```java
Stream<String> ids = ...;
Stream<User> users = ids.map(Users::lookup)
    .filter(Optional::isPresent)
    .map(Optional::get);
```

然而以下调用更加优雅

```java
Stream<User> users = ids.map(Users::lookup)
    .flatMap(Optional::stream);
```

```java
package optional;

import java.io.IOException;
import java.nio.file.*;
import java.util.*;
/**
 * @author Cay Horstmann
 */

public class OptionalTest
{
    public static void main(String[] args) throws IOException
    {
        var contents = Files.readString(Paths.get("../gutenberg/alice30.txt"));
        List<String> wordList = List.of(contents.split("\\PL+"));

        Optional<String> optionalValue = wordList.stream().filter(s -> s.contains("fred")).findFirst();
        System.out.println(optionalValue.orElse("No word") + " contains fred");

        Optional <String> optionalString = Optional.empty();
        String result = optionalString.orElse("N/A");
        System.out.println("result: " + result);
        result = optionalString.orElseGet(() -> Locale.getDefault().getDisplayName());
        System.out.println("result: " + result);
        try{
            result = optionalString.orElseThrow(IllegalStateException::new);
            System.out.println("result: " + result);
        }
        catch(Throwable t)
        {
            t.printStackTrace();
        }
        optionalValue = wordList.stream()
                .filter(s -> s.contains("red"))
                .findFirst();
        optionalValue.ifPresent(s -> System.out.println(s + " contains red"));

        var results = new HashSet<String>();
        optionalValue.ifPresent(results::add);
        Optional<Boolean> added = optionalValue.map(results::add);
        System.out.println(added);

        System.out.println(inverse(4.0).flatMap(OptionalTest::squareRoot));
        System.out.println(inverse(-1.0).flatMap(OptionalTest::squareRoot));
        System.out.println(inverse(0.0).flatMap(OptionalTest::squareRoot));
        Optional<Double> result2 = Optional.of(-4.0)
                .flatMap(OptionalTest::inverse).flatMap(OptionalTest::squareRoot);
        System.out.println(result2);

    }
    public static Optional<Double> inverse (Double x)
    {
        return x == 0 ? Optional.empty() : Optional.of(1 / x);
    }
    public static Optional<Double> squareRoot(Double x)
    {
        return x < 0 ? Optional.empty() : Optional.of(Math.sqrt(x));
    }
}
```

## 收集结果

当处理完流后， 可以调用iterator方法， 它会产生访问元素的旧式风格的迭代器

或者调用forEach语言， 将某个函数应用于每个元素

```java
stream.forEach(System.out::println);
```

并行流中forEach以任意顺序遍历各个元素

更常见的情况是创建一个数组

```java
String[] result = stream.toArray(String[]::new);
```

针对将流中的元素收集到另一个目标中， 有一个collect方法可用

```java
List<String> result = stream.collect(Collectors.toList());
```

```java
Set<String> result = stream.collect(Collectors.toSet());
TreeSet<String> result = stream.collect(Collectors.toCollection(TreeSet::new));
String result = stream.collect(Collectors.joining());
String result = stream.collect(Collectors.joining(", "));
String result = stream.map(Object::toString).collect(Collectors.joining(", "));
```

将流的结果约简为总和， 数量， 平均值， 最大值， 最小值：

```java
IntSummaryStatistics summary = stream.collect(
	Collectors.summarizingInt(String::length));
double averageWordLength = summary.getAverage();
double maxWordLength = summary.getMax();
```

```java
package collecting;

/**
 * @author Cay Horstmann
 */

import java.io.IOException;
import java.util.stream.*;
import java.nio.file.*;
import java.util.*;

public class CollectingResults
{
    public static Stream<String> noVowels() throws IOException
    {
        var contents = Files.readString(Paths.get("../gutenberg/alice30.txt"));
        List<String> wordList = List.of(contents.split("\\PL+"));
        Stream<String> words = wordList.stream();
        return words.map(s -> s.replaceAll("[aeiouAEIOU]", ""));
    }
    public static <T> void show(String label, Set<T> set)
    {
        System.out.println(label + ": " + set.getClass().getName());
        System.out.println("[" +
                set.stream().limit(10).map(Object::toString).collect(Collectors.joining(", "))
                + "]");
    }

    public static void main(String[] args) throws IOException {
        Iterator<Integer> iter = Stream.iterate(0, n ->n + 1).limit(10).iterator();
        while (iter.hasNext())
            System.out.println(iter.next());

        Object[] numbers = Stream.iterate(0, n -> n + 1).limit(10).toArray();
        System.out.println("Object array: " + numbers);

        //Note it's an Object[] array

        try {
            var number = (Integer) numbers[0];
            System.out.println("number: " + number);
            System.out.println("The following statement throws an exception: ");
            var numbers2 = (Integer[]) numbers;     //Throws Exception
        }
        catch (ClassCastException ex)
        {
            System.out.println(ex);
        }

        Integer[] numbers3 = Stream.iterate(0, n -> n + 1).limit(10).toArray(Integer[]::new);
        System.out.println("Integer[] array: " + numbers3);
        // Note it's an Integer[] array

        Set<String> noVowelSet = noVowels().collect(Collectors.toSet());
        show("noVowelSet", noVowelSet);

        TreeSet<String> noVowelTreeSet = noVowels().collect(Collectors.toCollection(TreeSet::new));
        show("noVowelTreeSet", noVowelTreeSet);

        String result = noVowels().limit(10).collect(Collectors.joining());
        System.out.println("Joining: " + result);
        result = noVowels().limit(10).collect(Collectors.joining(", "));
        System.out.println("Joining with commas: " + result);

        IntSummaryStatistics summary = noVowels().collect(Collectors.summarizingInt(String::length));
        double averageWordLength = summary.getAverage();
        double maxWordLength = summary.getMax();
        System.out.println("Average word length: " + averageWordLength);
        System.out.println("Max word length: " + maxWordLength);
        System.out.println("forEach:");
        noVowels().limit(10).forEach(System.out::println);
    }
}
```



## 收集到映射表中

假设存在Stream< Person >

```java
Map<Integer, String> idToName = people.collect(Collectors.toMap(Person::getId, Person::getName));
```

通常情况下值应该是实际的元素

```java
Map<Integer, Person> idToPerson = people.collect(Collectors.toMap(Person::getId, Function::identity()));
```

可以通过提供第三个参数来解决IllegalStateException

```java
        Stream<Locale> locales = Stream.of(Locale.getAvailableLocales());
        Map<String, String> languageNames = locales.collect(
                Collectors.toMap(
                        Locale::getDisplayLanguage, loc ->loc.getDisplayLanguage(loc), (existingValue, newValue) ->existingValue));
     
```



若想要了解给定国家的所有语言

```java

        Stream <Locale> locales = Stream.of(Locale.getAvailableLocales());
        Map<String, Set<String>> countryLanguageSets = locales.collect(
                Collectors.toMap(
                        Locale::getDisplayCountry, l ->Collections.singleton(l.getDisplayLanguage()),
                        (a, b) -> {
                            var union = new HashSet<String>(a);
                            union.addAll(b);
                            return union;
                        }));
```



若想得到TreeMap， 将构造器作为第四个引元， 必须提供一种合并函数

```java
Map<Integer, Person> idToPerson = people.collect(
	Collectors.toMap(
    Person::getId, 
    Function::identity(),
    (existingValue, newValue) -> {throw new IllegalStateException();},
    TreeMap::new));
```

```java
package collecting;

import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * @author Cay Horstmann
 */
public class CollectingIntoMaps
{
    public static class Person
    {
        private int id;
        private String name;
        public Person (int id, String name)
        {
            this.id = id;
            this.name = name;
        }

        public int getId() {
            return id;
        }

        public String getName() {
            return name;
        }

        @Override
        public String toString() {
            return getClass().getName() +
                    "[id=" + id + ", name=" + name + ']';
        }
    }
    public static Stream<Person> people()
    {
        return Stream.of(new Person(1001, "Peter"), new Person(1002, "Paul"), new Person(1003, "Mary"));
    }

    public static void main(String[] args) {
        Map<Integer, String> idToName = people().collect(
                Collectors.toMap(Person::getId, Person::getName)
        );
        System.out.println("idToName: " + idToName);

        Map<Integer, Person> idToPerson = people().collect(Collectors.toMap(Person::getId, Function.identity()));
        System.out.println("idToPerson: " + idToPerson.getClass().getName() + idToPerson);

        idToPerson = people().collect(Collectors.toMap(Person::getId, Function.identity(),
                (existingValue, newValue) -> {throw new IllegalStateException();}, TreeMap::new));
        System.out.println("idToPerson: " + idToPerson.getClass().getName() + idToPerson);

        Stream<Locale> locales = Stream.of(Locale.getAvailableLocales());
        Map<String, String> languageNames = locales.collect(
                Collectors.toMap(Locale::getDisplayLanguage, l -> l.getDisplayLanguage(l),
                        (existingValue, newValue) -> existingValue)
        );
        System.out.println("languageNames: " + languageNames);

        locales = Stream.of(Locale.getAvailableLocales());
        Map<String, Set<String>> countryLanguageSets = locales.collect(
                Collectors.toMap(Locale::getDisplayCountry, l -> Set.of(l.getDisplayLanguage()),
                        (a, b) ->
                        {
                            Set<String> union = new HashSet<>(a);		//将
                            union.addAll(b);
                            return union;
                        }));
        System.out.println("countryLanguageSets: " + countryLanguageSets);
    }
}
```

## 群组和分区

上一节收集给定国家的所有语言其处理略显冗长， 然而， 将具有相同特性的值群聚成组是非常常见的。

```java
Map<String, List<Locale>> countryToLocales = locales.collect(
    Collectors.groupingBy(Locale::getCountry));
```

Locale::getCountry是群组的分类函数， 现在可以查找指定国家代码对应的所有地点

```java
List<Locale> swissLocales = countryToLocales.get("CH");
//Yields locales de_CH, fr_CH, it_CH and maybe more
```

当分类函数是断言函数时， 使用partitioningBy比使用grouping更高效

```java
Map<Boolean, List<locale>> englishAndOtherLocales = locales.collect(
	Collectors.partitioningBy(l -> l.getLanguage().equals("en")));
List<Locale> englishLocales = englishAndOtherLocales.get(true);
```

#  下游收集器

如果想要以某种方式来处理这些列表， 需要一个下游收集器

```java
Map<String, Set<Locale>> countryToLocaleSet = locales.collect(
	groupingBy(Locale::getCountry, toSet()));
```



 counting会产生收集到的元素的个数

```java
Map<Strign, Long> countryToLocaleCounts = locales.collect(
	groupingBy(Locale::getCountry, counting())); 
```



summing(Int| Long | Double)

接受一个函数作为引元， 将该函数应用到下流元素中， 并产生其和

```javav\
Map<String, Integer> stateToCityPopulation = cities.collect(
	groupingBy(City::getState, summingInt(City::getPopulation)));
```



maxBy和minBy会接受一个比较器， 返回最大值 /  最小值

```java
map<Sting, Optional<City>> stateToLargestCity = cities.collect(
	groupingBy(City::getState,
              maxBy(Comparator.comparing(City::getPopulation)))); 
```

collectingAndThen收集器在收集器后面添加了最终处理步骤

```java
Map<Character, Integer> stringCountsByStartingLetter = strings.collect(
	groupingBy(s -> s.charAt(0), collectingAndThen(toSet(), Set::size)));
```

 

mapping收集器将一个函数应用到每一个元素

```java
Map<Character, Set<Integer>> stringLengthByStartingLetter = strings.collect(
	groupingBy(s -> s.charAt(0), 
              mapping(String::length, toSet())));
```

```java
Map<String, Set<String>> countryToLanguages = locales.collect(
	groupingBy(Locale::getDisPlayCountry,
              mapping(Locale::getDisplaylanguage, toSet())));
```

还有一个flatMapping方法， 可以与返回流的函数一起用

若群组和映射函数的返回值为int， long, 或double， 那么可以将元素收集到汇总统计对象中

```java
Map<String, IntSummaryStatistics> stateToCityPopulationSummary = cities.collect(
	groupingBy(City::getState, summarizingInt(City::getPopulation)));
```



filtering收集器会将一个过滤器应用到每个组上

```java
Map<String, Set<City>> largeCitiesByState
    = cities.collect(groupingBy(City::getState, 
                               filtering(c -> c.getPopulation() > 500000, toSet())));
```



```java
package collecting;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.stream.*;
import java.util.*;
import static java.util.stream.Collectors.*;

/**
 * @author Cay Horstmann
 */
public class DownstreamCollectors
{
    public static class City
    {
        private String name;
        private String state;
        private int population;
        public City(String name, String state, int population)
        {
            this.name = name;
            this.population = population;
            this.state = state;
        }

        public String getName() {
            return name;
        }

        public int getPopulation() {
            return population;
        }

        public String getState() {
            return state;
        }
    }
    public static Stream<City> readCities (String filename) throws IOException
    {
        return Files.lines(Paths.get(filename))
                .map(l -> l.split(", "))
                .map(a -> new City(a[0], a[1], Integer.parseInt(a[2])));
    }

    public static void main(String[] args) throws IOException
    {
        Stream<Locale> locales = Stream.of(Locale.getAvailableLocales());
        Map<String, Set<Locale>> countryToLocaleSet = locales.collect(
                groupingBy(Locale::getCountry, toSet()));
        System.out.println("countryToLocaleSet: " + countryToLocaleSet);

        locales = Stream.of(Locale.getAvailableLocales());

        Map<String, Long> countryToLocaleCounts = locales.collect(
                groupingBy(Locale::getCountry, counting()));
        System.out.println("countryToLocalCounts: " + countryToLocaleCounts);

        Stream<City> cities = readCities("../cities.txt");
        Map<String, IntSummaryStatistics> stateToCityPopulationSummary = cities
                .collect(groupingBy(City::getState, summarizingInt(City::getPopulation)));
        System.out.println(stateToCityPopulationSummary.get("NY"));

        cities = readCities("../cities.txt");
        Map<String, String> stateToCityNames = cities.collect(
                groupingBy(City::getState,
                        reducing("", City::getName, (s, t) -> s.length() == 0 ? t : s + ", " + t)));
        System.out.println("stateToCityNames: " + stateToCityNames);

        cities = readCities("../cities.txt");
        stateToCityNames = cities.collect(
                groupingBy(City::getState, mapping(City::getName, joining(", "))));
        System.out.println("stateToCityNames: " + stateToCityNames);
    }
}
```



# 约简操作

reduce方法是一种从流中计算某个值的通用机制

```java
List<Integer> values = ...;
Optional <Integer> sum = values.stream().reduce((x, y) -> x + y);
```

若有幺元e使得e op x = x， 则

```java
List<Integer> values = ...;
Integer sum = values.stream().reduce(0, (x, y) -> x + y);
```

若流为空， 返回幺元值。

对于例如求字符串流中所有字符串的长度。

需要提供一个“累积器”函数（total, word） -> total + word.length().

当计算并行化， 需要提供第二个参数提供结果合并

```java
int result = words.reduce(0, 
                         (total, word) -> total + word.length(), 
                         (total1, total2) -> total1 + total2);
```

## 基本类型流

```java
IntStream stream = IntStream.of(1, 1, 2, 3, 5);
stream = Arrays.stream(values, from, to); 			//values is an int[] array
```

还可以使用静态generate和iterate方法， IntStream和LongStream有静态方法range和rangeClosed， 可以生成步长为1的整数范围

```java
IntStream zeroToNinetyNine = IntStream.range(0, 100);        
IntStream zeroToHundred = IntStream.rangeClosed(0, 100);
```

CharSequence接口有codePoints和chars方法

```java
        String sentence = "\uD835\uDD46 is the set of octonions.";
        // \uD935\uDD46 is the UTF-16 encoding of the letter unicode U+1D546
        

        IntStream codes = sentence.codePoints();
        // The stream with hex values 1D546 20 69 73 20 . . .
```



当有一个对象流时， 可以使用maptoInt， maptoLong或mapToDouble将其转换为基本类型流

```java
Stream<String> words = ...;
IntStream lengths = words.mapToInt(String::length);
```

将基本类型转换为对象流需要使用boxed方法

```java
Stream<Integer> integers = IntStream.range(0, 100).boxed();
```

这种流有如下差异：

1. toArray方法返回基本数据类型数组
2. 产生可选结果的方法会返回一个OptionalInt， OptionalLong或OptionalDouble。 但是具有getAsInt， getAsLong, getAsDouble方法， 而不是get方法
3. 具有分别返回总和， 最大值， 最小值和平均值的sum, max, min, average方法
4. summaryStatistics方法会产生一个类型为IntSummaryStatistics， LongSummaryStatistics或DoubleSummaryStatistics的对象

```java
package streams;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import java.util.stream.Stream;

/**
 * @author Cay Horstmann
 */
public class PrimitiveTypeStreams
{
    public static void show(String title, IntStream stream)
    {
        final int SIZE = 10;
        int[] firstElements = stream.limit(SIZE + 1).toArray();
        System.out.print(title + ": ");
        for (int i = 0; i < firstElements.length; i++)
        {
            if(i > 0) System.out.print(", ");
            if(i < SIZE)
                System.out.print(firstElements[i]);
            else
                System.out.print("...");
        }
        System.out.println();
    }

    public static void main(String[] args) throws IOException
    {
        IntStream is1 = IntStream.generate(() -> (int) (Math.random() * 100));
        show("is1", is1);

        IntStream is2 = IntStream.range(5, 10);
        show("is2", is2);

        IntStream is3 = IntStream.rangeClosed(5, 10);
        show("is3", is3);

        Path path = Path.of("../gutenberg/alice30.txt");
        var contents = Files.readString(path);

        Stream<String> words = Stream.of(contents.split("\\PL+"));
        IntStream is4 = words.mapToInt(String::length);
        show("is4", is4);
        var sentence = "\uD835\uDD46 is the set of octonions.";
        System.out.println(sentence);

        IntStream codes = sentence.codePoints();
        System.out.println(codes.mapToObj(c -> String.format("%x", c)).collect(Collectors.joining()));

        Stream<Integer> integers = IntStream.range(0, 100).boxed();
        IntStream is5 = integers.mapToInt(Integer::intValue);
        show("is5", is5);
    }
}
```



## 并行流

流使并行操作变得容易。

Collection.parallelStream()方法从任何集合获取一个并行流

首先要有一个并行流

```java
Stream<String> parallelWords = words.parallelStream();
```

parallel方法可以将任意的顺序流转换为并行流

```java
Stream<String> parallelWords = Stream.of(wordArray).parallel();
```

对短单词进行计数：

```java
Map<Integer, Long> shortWordCounts = words.parallelStream()
    .filter(s->s.length() < 12)
    .collect(groupingBy(
    String::length, counting()));
```

* 并行化会导致大量开销， 只有面对非常大的数据集才划算
* 只有底层数据源可以被有效分割为多个部分时并行化才有意义
* 并行流使用的线程池可能因为诸如文件I/O或网络访问这样的操作被阻塞而饿死



```java
package ParallelStreams;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static java.util.stream.Collectors.counting;

/**
 * @author Cay Horstmann
 */
public class ParallelStreams
{
    public static void main(String[] args) throws IOException
    {
        var contents = Files.readString(Path.of("../gutenberg/alice30.txt"));

        List<String> wordList = List.of(contents.split("\\PL+"));

        //Very bad code ahead
        var shortWords = new int[10];
        wordList.parallelStream().forEach(s ->
        {
            if(s.length() < 10) shortWords[s.length()]++;
        });
        System.out.println(Arrays.toString(shortWords));

        //Try again--the result will likely be different(and also wrong)

        Arrays.fill(shortWords, 0);
        wordList.parallelStream().forEach(s ->
        {
            if(s.length() < 10) shortWords[s.length()]++;
        });
        System.out.println(Arrays.toString(shortWords));

        //Remedy: Group and count
        Map<Integer, Long> shortWordCounts = wordList.parallelStream()
                .filter(s -> s.length() < 10).collect(Collectors.groupingBy(String::length, counting()));
        System.out.println(shortWordCounts);

        //DownStream order not deterministic
        Map<Integer, List<String>> result = wordList.parallelStream().collect(
                Collectors.groupingByConcurrent(String::length));
        System.out.println(result.get(14));

        result = wordList.parallelStream().collect(
                Collectors.groupingByConcurrent(String::length));
        System.out.println(result.get(14));

        Map<Integer, Long> wordCounts = wordList.parallelStream().collect(
                Collectors.groupingByConcurrent(String::length, counting()));
        System.out.println(wordCounts);

    }
}
```













