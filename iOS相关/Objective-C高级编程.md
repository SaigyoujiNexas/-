# 自动引用计数
| 对象操作 | OC方法 |
| ---------| ------ |
| 生成对象 | alloc, new, copy等 |
| 持有对象 | retain方法 |
| 释放对象 | release方法 |
| 废弃方法 | dealloc方法 |

for a pointer point to an object, it will be
```objective-c
- (BOOL) performOperationWithError(NSError **)error;

//will compile to
- (BOOL) performOperationWithError(NSError * __autoreleasing *) error;
```
A variable marked with __autoreleasing will be registered to autoreleasepool, and get the object

```objective-c
NSError __strong *error = nil;
BOOL result = [obj performOperationWithError: &error];

//will compile to
NSError __strong *error = nil;
NSError __autoreleasing *tmp = error;
BOOL result = [obj performOperationWithError: &tmp];
error = tmp;
```

remember **self generate and get the object only when as the return value of alloc/new/copy/mutableCopy method**
使用C的内存申请函数时, 最好使用calloc, 而不是malloc
malloc 默认不将申请的内存设置为0, 会指向一个不确定的内存地址
释放内存时需要将内容对象置为nil, free不会做这件事

对于以下命令
```objective-c
{
    id __strong obj = [NSMutableArray array];
}
```
会编译成
```objective-c
{
    id obj = objc_msg_Send(NSMutableArray @selector(array));
    objc_retainAutoreleasedReturnValue(obj);
    objc_release(obj);
}
```

NSArray:
```objective-c
+ (id) array{
    id obj = objc_msgSend(NSMutableArray, @selector(alloc));
    objc_msgSend(obj, @selector(init));
    return objc_autoreleaseReturnValue(obj);
}
```

作用: 不让array中的obj对象注册到ARC, 而是让调用者被注册到ARC上, 节省调用次数

Core Foundation 框架转换NS框架时
__bridge: 不变更计数
__bridge_transfer: 释放掉右值
__bridge_retained: 右值对象增加引用计数(左值获得了一份所有权)

对weak类型进行调用时,编译器会进行tmp变量创建
```objective-c
{
    id __weak obj1 = obj;
    NSLog(@"%@", obj1);
}
```

```objective-c
{
    id obj1;
    objc_initweak(&obj1, obj);
    id tmp = objc_loadWeakRetained(&obj1);
    objc_autorelease(tmp);
    NSLog(@"%@", tmp);
    objc_destroyWeak(&obj1);
}
```
一次调用就创建一个tmp
十次就是十个

__autoreleasing 修饰符等价于ARC无效的autorelease方法

# Blocks

```objective-c
^void (int event) {
    printf("buttonId:%d event=%d\n", i, event);
}
```

block对截获变量的mutable为__block 关键字
```objective-c
__block int val = 0;
void (^blk)(void) = ^{val = 1; };
blk();
printf("val = %d\n", val);
```
block 无法获取C语言数组中的值,但是指针可以

## Block语法转换
```objective-c
int main(int argc, const char * args[]){
    void (^blk) (void) = ^{ printf("Block\n");};
    blk();
    return 0;
```


```objective-c++
struct __block_impl{
    void *isa;
    int Flags;
    int Reserved;
    void *FuncPtr;
};

struct __main_block_impl_0{
    struct __block_impl impl;
    struct __main_block_desc_0 Desc;

    __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags = 0){
        impl.isa = &_NSConcreteStackBlock;
        impl.Flags = flags;
        impl.FuncPtr = fp;
        Desc = desc;
    }
};

static void __main_block_func_0(struct __main_block_impl_0 *__cself){
    printf("Block\n");
};

static struct __main_block_desc_0 {
    unsigned long reserved;
    unsigned long Block_size;
} __main_block_desc_0_DATA = {
    0,
    sizeof(struct __main_block_impl_0)
};

int main(){
void (*blk) (void) = 
    (void (*) (void)) &__main_block_impl_0(
        (void *)__main_block_func_0, &__main_block_desc_0_DATA);

((void (*) (struct __block_impl *))
    (struct __block_impl *)blk->FuncPtr)((struct __block_impl *)blk);
}

```
对于截获变量lambda


```objective-c++

struct __block_impl{
    void *isa;
    int Flags;
    int Reserved;
    void *FuncPtr;
};

struct __main_block_impl_0{
    struct __block_impl impl;
    struct __main_block_desc_0 Desc;
    const char *fmt;
    int val;

    __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, const char *_fmt, int _val, int flags = 0): fmt(_fmt), val(_val){
        impl.isa = &_NSConcreteStackBlock;
        impl.Flags = flags;
        impl.FuncPtr = fp;
        Desc = desc;
    }
};

static void __main_block_func_0(struct __main_block_impl_0 *__cself){
    const char *fmt = __cself->fmt;
    int val = __cself->val;
    printf(fmt, val);
};

static struct __main_block_desc_0 {
    unsigned long reserved;
    unsigned long Block_size;
} __main_block_desc_0_DATA = {
    0,
    sizeof(struct __main_block_impl_0)
};

int main(){
    int dmy = 256;
    int val = 10;
    const char *fmt = "val = %d\n";
void (*blk) (void) = (void (*) (void)) &__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, fmt, val);

((void (*) (struct __block_impl *))(struct __block_impl *)blk->FuncPtr)((struct __block_impl *)blk);
}
```

mutable 截获变量的转换
```objective-c++
struct __Block_byref_val_0{
        void *__isa;
        __Block_byref_val_0 *__forwarding;
        int __flags;
        int __size;
        int val;
};
struct __block_impl{
    void *isa;
    int Flags;
    int Reserved;
    void *FuncPtr;
};

struct __main_block_impl_0{
    struct __block_impl impl;
    struct __main_block_desc_0* Desc;
    __Block_byref_val_0 *val;
    __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, __Block_byref_val_0 *_val, int flags = 0): val(_val->__forwarding){
        impl.isa = &_NSConcreteStackBlock;
        impl.Flags = flags;
        impl.FuncPtr = fp;
        Desc = desc;
    }
};

static void __main_block_func_0(struct __main_block_impl_0 *__cself){
    __Block_byref_val_0 *val = __cself->val;

    (val->__forwarding->val) = 1;
};

static void __main_block_copy_0(
    struct __main_block_impl_0* dest, struct __main_block_impl_0* src
){
    _Block_object_assign(&dest->val, src->val, BLOCK_FIELD_IS_BYREF);
}

static void __main_block_dispose_0(struct __main_block_impl_0 *src){
    _Block_object_dispose(src->val, BLOCK_FIELD_IS_BYREF);
}

static struct __main_block_desc_0 {
    unsigned long reserved;
    unsigned long Block_size;
    void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
    void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = {
    0,
    sizeof(struct __main_block_impl_0),
    __main_block_copy_0,
    __main_block_dispose_0,
};

int main(){
    __Block_byref_val_0 val = {
        0,
        &val,
        0,
        sizeof(__Block_byref_val_0),
        10,
    };
    blk = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA, &val, 0x22000000);
    return 0;
}
```

val 相当于原来的自动变量的成员变量

Block的类有三种:

- _NSConcreteStackBlock
- _NSConcreteGlobalBlock
- _NSConcreteMallocBlock

分别对应程序的栈区, 数据区, 堆区

解决由于截获变量被释放与block所在作用域释放导致block内部数据无法索引的问题, 编译器会自动将block转移到堆
```objective-c++
blk_t func(int rate){
    blk_t tmp = &__func_block_impl_0(
        __func_block_func_0, &__func_block_desc_0_DATA, rate);
    tmp = objc_ratainBlock(tmp);
    return objc_autoreleaseReturnValue(tmp);
}
```
objc_ratainBlock内部
```objective-c++
tmp = _Block_copy(tmp);
return objc_autoreleaseReturnValue(tmp);
```
当截获变量即将被释放时,调用_Block_copy函数, 会调用__main_block_copy_0调用将__block变量所有权转移
block被释放时会调用__main_block_dispose来释放截获变量
Block 可能导致循环引用(持有外部引用), 记得用__weak, 好用

# GCD

## 线程队列
- Serial Dispatch Queue 单线程池
- Concurrent Dispatch Queue 多线程池

dispatch queue 需要手动释放, 这个不归ARC管
```objective-c
dispatch_release(mySerialDispatchQueue);
```

变更队列优先级:

```objective-c
dispatch_queue_t globalDispatchQueueBackground = 
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
dispatch_set_target_queue(mySerialDispatchQueue, globalDispatchQueueBackground);
```


## 调用函数

- dispatch_async 异步执行 == Handler.post{ Log.d("test") }
- dispatch_after 延迟执行 == Handler.post(1000){ Log.d("test") }
- dispatch_group_create 创建线程组 相当于Kotlin中,CoroutineScope.runBlock{}
- dispatch_group_create 线程组内运行, 相当于Kotlin中 runBlock里的launch
- dispatch_group_notify 异步线程组完成回调
- dispatch_group_wait 同步线程组完成等待
- dispatch_barrier_async 要求前置任务完成, 相当于JVM中的读写屏障
- dispatch_sync 同步执行
- dispatch_apply 一次提交n个任务上去
- dispatch_suspend 线程队列挂起
- dispatch_resume 线程队列恢复
- dispatch_semaphore_create 创建信号量
- dispatch_semaphore_wait P行为
- dispatch_semaphore_signal V行为
- dispatch_once 约等于Kotlin的 by lazy
- dispatch_io_create 创建多线程IO
- dispatch_io_set_low_water 设定一个线程读多少
- dispatch_io_read 开始读取
- dispatch_data_create_map 组装多线程读取的data



