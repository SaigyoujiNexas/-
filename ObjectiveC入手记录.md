# OC - Hello World

```objective-c
#import <Foundation/Foundation.h>

int main(){
    NSLog(@"Hello, World!");
    return 0;
}
```

NSLog是OC的输出函数，看起来只是printf换了个名字？

在字符串前面加@是将其转化为OC特有的数据类型

```objective-c
char* str1 = "Objective-C";
NSString *str2 = @"Objective-C";
```

加@成NSString了

```objective-c
#import <Foundation/Foundation.h>

int main(){
    int a = 100;
    float b = 39.2;
    char* str1 = "Objective-C";
    NSString* str2 = @"Kotlin is best";
    NSLog(@"a: %d\nb: %f\nstr1: %s\nstr2: %@\n", a, b, str1, str2);
}
```

NSString的format转义字符是%@

## 为什么辣么多NS？

乔布斯在离开apple后创建的公司叫NeSt， 并开发了Foundation框架， 乔布斯以此来纪念自己的公司。

# OC - 面向对象

```objective-c
#import <Foundation/Foundation.h>

@interface Student: NSObject
    @property NSString* name;
	@property int age;
	@property float score;
	-(void) display;   //类所包含的函数
@end //类声明结束

@implementation Student
    -(void) display {
    	NSLog(@"%@的年龄是 %d, 成绩是 %f", self.name, self.age, self.score);
	}
@end
    
int main(int argc, const char* argv[]){
    Student * stu1 = [[Student alloc] init];
    stu1.name = @"小明";
    stu1.age = 15;
    stu1.score = 92.5;
    //调用类函数
    [stu1 display];
    return 0;
}
```

声明类的属性需要@property关键字， 而声明类的方法不需要使用任何关键字。

## 类框架

.h文件中的代码

```objective-c
#import <Foundation/Foundation.h>

@interface Person: NSObject {
    //declare the member variable
}
//declare the property and method
@end
```

.m文件中的代码

```objective-c
@import "Person.h"
// import other header file

// add class extension
@implementation Person 
    //implement the method declared.
@end
```

## 类方法与对象方法

类方法： 就是 java 里的 static method

```objective-c
+(int)persionWithA1: (float)a1 andA2: (NSString*) a2; //a1, a2分别代表两个参数
```

对象方法: 就是java 里的 non static method

```objective-c
-(int)persionWithA1: (float)a1 andA2: (NSString*) a2;
```

### 调用

类方法：

```objective-c
[Person persionWithA1:2 andA2:@"类方法"]; //调用对象是类名
```

对象方法：

```objective-c
Person * obj1 = [[Person alloc]init];
[obj1 personWithA1: 1 andA2:@"对象方法"];
return 0;
```

## class extension

类扩展是用来添加私有属性或方法的

代码格式：

```objective-c
@interface Person (){ // append a class extension to Person class
    // add member variable
}
//add property
//add method
@end
```

## @property 的几种常用修饰词

### nonatomic & atomic

nonatomic: 非原子性

atomic: 原子性 (默认)

### copy, strong & weak

copy： 一般用于字符串， 将内容拷贝一份， 保存在一个单独的存储空间中。

strong： 强引用， 不受gc影响， 引用计数

weak: 弱引用， gc后就没了

### assign, readonly & readwrite

assign: 应用于OC & C的基础类型， 在栈中开辟内存

readwrite(默认): 这个属性可读可写（有get方法 & set 方法）

readonly: 只读

### setter & getter

getter = method, 使用它给这个属性指定get方法

setter = method, 使用它给这个属性设置set方法

### 使用方法

```objective-c
@property (nonatomic, strong) Person* person;
```

# 命名规则

1. 类名每个单词首字母大写
2. 类中属性名第一个单词首字母小写， 后边每个单词首字母大写
3. 类中方法名第一个单词首字母小写， 后边每个单词首字母大写。 参数命名规则和属性相同。

# 消息机制

对于OC而言， 调用方法被称为：向这个类(类方法) 或则类对象(对象方法)发送消息。

例如

```objective-c
[person say]
```

编译后

```objective-c
objc_msgsend(person @selector(say));
```

## 背后的原因 -- 动态特性

ps: 我感觉这tm就是个坑， 还动态特性， 我呸， 就该编译时把全部问题代码查出来，不修好不给编译通过

### 动态类型

当无法知道数据的具体类型时, 可以将数据直接存储到id类型对象里

(人话： 编译时全部看成id类型对象)

### 动态绑定

只有在程序运行时才能确定对象的具体属性和方法，从而进行绑定。

例如：

Person.h：

```objective-c
#import <Foundation/Foundation.h>
@interface Person : NSObject
-(void) exercise;
@end
```

Person.m:

```objective-c
#import "Person.h"
@implementation Person
-(void)exercise {
    NSLog(@"I am running!!!");
}
@end
```

main.m:

```objective-c
#import <Foundation/Foundation.h>
#import "Person.h"

int main(int argc, const char* argv[]){
    Person* person = [[Person alloc] init];
    id person1 = [[NSObject alloc] init];
    [person1 exercise];
    [person exercise];
    return 0;
}
```

代码是可以编译通过的

tips: 6完了，有点太信任程序员了



# OC中的类别

在现有类的基础上为该类增加一些新的方法即为类别(别名：扩展类， 类目)

类别与类扩展的区别：

* 同： 类扩展和类别都可以为原有类增加新的方法
* 异： 类扩展添加的方法外界无法调用，而类别可以， 类扩展可以添加属性，而类别只能添加方法

ps： 类别有点像扩展函数

Person.h

```objective-c
#import <Foundation/Foundation.h>
@interface Person: NSObject
    @property (nonatomic, copy) NSString* name;
@property (nonatomic, assign)int age;
-(void) run;
@end
```

Person.m

```objective-c
#import "Person.h"
@implementation Person 
    -(void) run {
    NSLog(@"the person is running!");
}
@end
```

Person+NewFunction.h

```objective-c
#import "Person.h"
@interface Person (NewFunction)
    //add method
@end
```

1. 创建类时引入Foundation框架， 而类别则是引入原有类的头文件
2. 创建类时， 父类被"(类别名)"(即NewFunction)替代了

Person+NewFunction.m

```objective-c
#import "Person+NewFunction.h"
@implementation Person (NewFunction)
    //implement method
@end
```

# 协议

OC为单继承多协议语言(java 的 implementation?)

1. 协议没有父类（协议可以服从多个协议， 一般服从NSObject协议)
2. 协议中不能定义变量与属性， 只能定义方法

ps： 这不就是接口？？？？
## 创建

Children.h

```objective-c
#import <Foundation/Foundation.h>
@protocol CHildrenDelegate <NSObject>
-(void) eat;
@end
@interface Children: NSObject
@property(nonatomic, weak)id<ChildrenDelegate>delegate;
@end
```

协议中有以下几个修饰词：

* @required(默认， 表示以下方法必须被实现)
* @optional(以下方法可以不实现)

\<ChildrenDelegate\> 表明这个属性方法和这个协议相关联

delegate： 代理属性名， 一般命名为delegate，表明这是一个代理属性

## 实际应用

接下来在nanny这个类中实现协议

Nanny.h

```objective-c
#import <Foundation/Foundation.h>
#import "Children.h"
@interface Nanny: NSObject<ChildrenDelegate>
@end
```

Nanny.m

```objective-c
#import "Nanny.h"
@implementation Nanny
-(void)eat{
	NSLog(@"the nanny is taking care of the child eating something!");
}
@end
```

main.m

```objective-c
#import <Foundation/Foundation.h>
#import "Children.h"
#import "Nanny.h"
int main(int argc, char* argv[]){
    Children * child = [[Children alloc] init];
    Nanny * nanny = [[Nanny alloc] init];
    child.delegate = nanny;
    if([child.delegate respondsToSelector:@selector(eat)])
        [child.delegate eat];
    return 0;
}
```

ps：对不起， 协议看起来还不像接口， 而是像kotlin 里的 by

child.delegate 本质上就是nanny对象

# 单例

Car.h

```objective-c
#import <Foundation/Foundation.h>
@interface Car: NSObject
@property (nonatomic, assign) int driveHours;
+ (instancetype)car;
@end
```

Car.m

```objective-c
#import "Car.h"

static Car* car = nil;
@implementation Car
+(instancetype)car{
    if(car == nil) {
        car = [[Car alloc] init];
    }
    return car;
}
@end
```

static的作用： 使这个对象只分配一次内存(静态的嘛， 很正常)

Person.h

```objective-c
#import <Foundation/Foundation.h>
#import "Car.h"
@interface Person : NSObject
@property (nonatomic, copy) NSString * name;
@property (nonatomic, strong) Car * car;
-(void) displayWithDriveHours: (int)hours;
@end
```

Person.m

```objective-c
#import "Person.h"
@implementation Person
-(instancetype) init {
    if(self = [super init]) {
        self.car = [Car car];
        self.name = nil;
    }
    return self;
}
-(void) displayWithDriveHours:(int) hours{
    self.car.driveHours += hours;
}
@end
```

main.m

```objective-c
#import <Foundation/Foundation.h>
#import "Person.h"

int main(int argc, char* argv[]){
    Person * ZhangSan = [[Person alloc] init];
    
    Person* LiSi = [[Person alloc] init];
    [LiSi displayWithDriveHours:5];
    [ZhangSan displayWithDriveHours: 10];
    
    [LiSi displayWithDriveHours: 3];
    Car * car = [Car car];
    NSLog(@"The allHours are %d", car.driveHours);
    return 0;
}
```

输出： The allHours are 18

# NSString

## 创建

```objective-c
+ (instancetype)stringWithString:(NSString*)string;
- (instancetype)initWithString: (NSString*)aString;
```



instancetype和id的意义一样， 但是instancetype返回值强制为本类的对象

当运用这两种方式， XCode提示直接使用

```objective-c
NSString * str = @"";
```

这种形式





```objective-c
+ (instancetype)stringWithFormat:(NSString*)format;
```

可以使用该方法将一些外界的变量或常量与任意字符串进行组合

```objective-c
#import <Foundation/Foundation.h>
int main(){
    int count = 5;
    NSString * str = [NSString stringWithFormat:@"The count is :%d",count];
    NSLog(@"%@", str);
    return 0;
}
```

输出: The count is : 5

## 获取长度

```obje
#import <Foundation/Foundation.h>

int main(){
	int count = 5;
	NSString * str = [NSString stringWithFormat:@"The count is :%d",count];
	NSLog(@"%@", str);
	NSLog(@"%ld", [str length]); // 也可以是str.length
	return 0;
}
```

输出：

The count is : 5

15

## 判断字符串相等

```objective-c
#import <Foundation/Foundation.h>
int main() {
    NSString * str1 = @"abc";
    NSString * str2 = @"ABC";
    int equal = [str1 isEqualToString:str2];
    NSLog(@"%d", equal);
    return 0;
}
```

输出： 0

即该方法默认区分大小写

## 字符串比较

```objective-c
- (NSComparisonResult) compare: (NSString*) string;
```

该方法返回枚举详情：

```objective-c
typedef NS_ENUM(NSInteger, NSComparisonResult)
{NSOrderedAscending = -1L, NSOrderedSame, NSOrderedDescending};

NSOrderedAscending = -1,
NSOrderedSame = 0,
NSOrderedDescending = 1
```

使用

```objective-c
#import <Foundation/Foundation.h>
int main() {
    NSString * str1 = @"abc";
    NSString * str2 = @"ABC";
    int equal = [str1 compare:str2];
    NSLog(@"%d", equal);
    return 0;
}
```

## 判断子串

```objective-c
-(BOOL) containsString: (NSString *)str
```

```objective-c
#import <Foundation/Foundation.h>

int main(int argc, char* argv[]){
    NSString * str1 = @"a10b9c";
    NSString * str2 = @"b9c";
    int i = [str1 containsString: str2];
    NSLog(@"%d", i);
    return 0;
}
```

## NSMutableString

NSString跟java的String一样不可变， 要想改用NSMutableString

```objective-c
- (void) appendString: (NSString*) aString;
- (void) appendFormat: (NSString*) format,...;
- (void) insertString: (NSString*) aString atIndex:(NSUInteger)loc;
- (void) deleteCharactersInRange: (NSRange) range;
```

对于NSRange:

```objective-c
typedef struct_NSRange{
    NSUInteger location;
    NSUInteger length;
} NSRange;
```

# NSArray

## 创建

```objective-c
+ (instancetype) arrayWithObjects: (ObjectType)firstObj, ...
- (instancetype) initWithObjects: (ObjectType) firstObj, ...
```

## 长度

NSArray提供了count属性和count方法用来获取长度

## 索引

```objective-c
- (ObjectType) objectAtIndex: (NSUInteger) index;
```

## 判断包含

```objective-c
- (BOOL)containsObject:(ObjectType)anObject;
```

类似kotlin， NSArray不可变

## NSMutableArray

```objective-c
-(void) addObject:(ObjectType)anObject;
-(void) addObjectsFromArray:(NSArray<ObjectType> *)otherArray;
- (void) removeAllObjects;
- (void) removeObject:(ObjectType)anObject;
```

# NSDictionary

ps： HashMap?还真是

```objective-c
+ (instancetype) dictionaryWithObject:(ObjectType) object forKey:(KeyType <NSCopying>) key;
+ (instancetype) dictionaryWithObjects:(NSArray<ObjectType> *) objects, forKeys:(NSArray<KeyType<NSCopying>> *) keys;

+ (instancetype) dictionaryWithObjectsAndKeys:(id)firstObject, ...;
- (instancetype) initWithObjectsAndKeys:(id)firstObject, ...;
```

```objective-c
#import <Foundation/Foundation.h>
int main() {
    NSDictionary * dic1=[NSDictionary dictionaryWithObject:@"object1" forKey:@"key1"];
    NSLog(@"dic1 has :%@",dic1);

    NSDictionary * dic2=[NSDictionary 
                         dictionaryWithObjects:
                         [NSArray arrayWithObjects:@"object1",@"object2",@"object3", nil] 
                         forKeys:
                         [NSArray arrayWithObjects:@"key1",@"key2",@"key3", nil]];
    NSLog(@"dic2 has :%@",dic2);
    
    NSDictionary * dic3=[
        NSDictionary dictionaryWithObjectsAndKeys:
        @"object1",@"key1",@"object2",@"key2",@"object3",@"key3", nil];
    NSLog(@"dic3 has :%@",dic3);
    
    NSDictionary * dic4=
        [[NSDictionary alloc] initWithObjectsAndKeys:
         @"object1",@"key1",@"object2",@"key2",@"object3",@"key3", nil];
    NSLog(@"dic4 has :%@",dic4);
    return 0;
}
```

count属性与方法返回键值对数量

## 判断两个字典是否相等

```objective-c
- (BOOL) isEqualToDictionary: (NSDictionary<KeyType, ObjectType> *) otherDictionary;
```

```objective-c
#import <Foundation/Foundation.h>
int main(){
    NSDictionary * dic2 = 
        [NSDictionary
         dictionaryWithObjects: [
             NSArray arrayWithObjects:@"object1",@"object2",@"object3", nil] 
         forKeys:[
             NSArray arrayWithObjects:@"key1",@"key2",@"key3", nil]
        ]
    ];
    NSDictionary * dic3=
        [NSDictionary
         dictionaryWithObjectsAndKeys:
         @"object1",@"key1",@"object2",@"key2",@"object3",@"key3", nil];
    int i = [dic2 isEqualToDictionary: dic3];
    NSLog(@"%d", i);
    return 0;
}
```

## 根据键找到对应的值

```objective-c
#import <Foundation/Foundation.h>
int main(){
    NSDictionary * dic2 = [
        NSDictionary dictionaryWithObjects:[
            NSArray arrayWithObjects:@"object1",@"object2",@"object3", nil] 
        forKeys:[NSArray arrayWithObjects:@"key1",@"key2",@"key3", nil]
    ];
    NSString * str = [dic2 objectForKey:@"key1"];
    NSLog(@"%@", str);
    return 0;
}
```

## 键集合 & 值集合

```objective-c
#import <Foundation/Foundation.h>

int main(){
    NSDictionary * dic2 = [
        NSDictionary dictionaryWithObjects:[
            NSArray arrayWithObjects:@"object1",@"object2",@"object3", nil] 
        forKeys:[NSArray arrayWithObjects:@"key1",@"key2",@"key3", nil]
    ];
    NSArray * keys = dic2.allKeys;
    NSArray * objects = dic2.allValues;
    
    NSLog(@"all keys are: %@", keys);
    NSLog(@"all values are : %@", objects);
    return 0;
}
```

同样类似Kotlin中的HashMap， 不可变

## NSMutableDictionary

```objective-c
- (void) setObject: (ObjectType) anObject forKey: (KeyType<NSCopying>)aKey;
- (viud) removeObjectForKey: (KeyType) aKey;
```

# NSDate

获取当前时间:

```objective-c
#import <Foundation/Foundation.h>

int main(){
    NsDate * date = [NSDate date];
    NSLog(@"%@", date);
    return 0;
}
```

```objective-c
+ (instancetype) date;
```

类似与java的SimpleDateFormatter， 也有NSDateFormatter

```objective-c
#import <Foundation/Foundation.h>
int main(int argc, char * argv[]){
    NSDate * date = [NSDate date];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"YYYY-MM--dd"];
    NSString * string = [formatter stringFromDate: date];
    NSLog(@"%@", string);
    [formatter setDateFormat: @"YYYY-MM--dd hh:mm"];
    string = [formatter stringFromDate: date];
    NSLog(@"%@", string);
    return 0;
}
```

输出:

2024-02--27

2024-02--27 20:35

# NSData

NSData的功能是操作二进制数据

当下载图片， 文件时， 通常返回的是二进制数据，此时需要使用通过NSData类生成的对象去接， 并通过NSData中提供的方法进行适当的类型转换，才算是真正的获取到数据

```objective-c
#import <Foundation/Foundation.h>
int main(){
    NSString * str = @"http://www.bilibili.com";
    NSData * data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"the data is :%@", data);
    NSString * strCopy = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding];
    NSLog(@"the new string is :%@", strCopy);
    return 0;
}
```

输出：

the data is :<68747470 3a2f2f63 2e626961 6e636865 6e672e6e
6574>
the new string is :http://c.biancheng.net

同样，NSData不可变， 如需修改NSData中的二进制数据， 需要使用NSMutableData

# OC中的包裹类

NSNumber类似与java中的Integer， NSNumber在这里装箱了C中的基本类型

NSValue则是装箱结构体， 转换为OC对象

```objective-c
#import <Foundation/Foundation.h>
int main(){
    int number = 5;
    
    NSNumber * intNum = [[NSNumber alloc] initWithInt: number];
    NSArray * array = [NSArray arrayWithObjects: intNum, nil];
    NSLog(@"the array is :%@", array);
    NSNumber * getNum = [array objectAtIndex: 0];
    int getNumber = [getNum intValue];
    NSLog(@"the number is : %d", getNumber);
    return 0;
}
```

```objective-c
#import <Foundation/Foundation.h>

int main(){
    NSRange range;
    range.length = 2;
    range.location = 1;
    
    NSValue * value = [NSValue valueWithRange: range];
    NSRange theRange = [value rangeValue];
    NSLog(@"%lu, %lu", (unsigned long)theRange.length, (unsigned long)theRange.location);
    return 0;
}
```

# OC中的通知

OC语言中采取了通知中心机制， 实现了一对多通信

wocker.m

```objective-c
#import "Wocker.h"
@implementation Worker
-(instancetype) init {
    if(self = [super init]) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self 
         selector:@selector(makeCar) name:@"canMake" object:nil
        ];
}
    return self;
}
-(void) makeCar {
    NSLog(@"Let's begin to make car, gogogo");
}
@end
```

`addObserver` 方法中的self对象是监听者对象，@selector是当创建的观察者接收到通知后要执行的方法，name参数表示监听消息名称，object为传递的参数

main.m

```objective-c
#import <Foundation/Foundation.h>
#import "Worker.h"

int main(int argc, const char * argv[]) {
    Worker * worker = [[Worker alloc] init];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"canMake" object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:worker name:@"canMake" object:nil];
    return 0;
}
```

# KVC & KVO



KVC = Key - Value - Coding

Person.h

```objective-c
#import <Foundation/Foundation.h>
@interface Person : NSObject
@property (nonatomic, copy) NSString* name;
@property (nonatomic, assign)int age;
@property (nonatomic, assign)int sex;
@end
```

main.m

```objective-c
#import <Foundation/Foundation.h>
#import "Person.h"
int main(int argc, const char* argv[]) {
    Person * person = [[Person alloc] init];
    [person setValue: @"ZhangSan" forKey: @"name"];
    [person setValue: [NSNumber numberWithInt: 10] forKey: @"age"];
    [person setValue: [NSNumber numberWithBool:YES] forKey:@"sex"];
    NSLog(@"The person's name is :@%, and age is :%d, sex is :%d",person.name, person.age, person.sex);
    return 0;
}
```

输出: The person's name is :ZhangSan, and age is :10, sex is :1

说白了，先开空间，然后在分配值， 类似java反射的createInstance()

