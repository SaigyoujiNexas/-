# RxJava笔记

## 转换操作符

###  groupBy

```java
private void test1() {
        //map: 直接对发射的事件进行处理， 再发射
        Observable<GroupedObservable<Object, String>> groupedObservableObservable =  Observable.just("test", "ttt", "betey", "test", "abfa", "test").groupBy(new Function<String, Object>() {
            @Override
            public Object apply(String s) throws Throwable {
                return s.startsWith("t");
            }
        });
        Observable.concat(groupedObservableObservable).subscribe(new Consumer<String>() {
            @Override
            public void accept(String s) throws Throwable {
                System.out.println(s);
            }
        });
    }
```

## 组合操作符

### concat

```java
Observable.concat(Observable.just("hello"), Observable.just("yesyesyes")
                , Observable.just("shit")).subscribe(
                        observer
        );
```

### merge

merge是并行的， 没有先后顺序

## 功能操作符

### subscribeOn

决定subscribe方法所在线程

```java
Observable.create(new ObservableOnSubscribe<Object>() {
            @Override
            public void subscribe(@NonNull ObservableEmitter<Object> emitter) throws Throwable {
                System.out.println(Thread.currentThread());
                Thread.sleep(2000);
                emitter.onNext("tetset");
                emitter.onNext("hello");
                emitter.onComplete();
            }
        }).subscribeOn(Schedulers.io()).subscribe(observer);
```

### observeOn

通过handler实现， 决定下游所在线程

```java
Observable.create(new ObservableOnSubscribe<Object>() {
            @Override
            public void subscribe(@NonNull ObservableEmitter<Object> emitter) throws Throwable {
                System.out.println(Thread.currentThread());
                Thread.sleep(2000);
                emitter.onNext("tetset");
                emitter.onNext("hello");
                emitter.onComplete();
            }
        }).subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread()).subscribe(observer);
    }
```



### doOnNext

在onNext方法之前调用

