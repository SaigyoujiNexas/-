# Effective-Objective-C

## 适应OC

### OC是消息调用， 而不是直接的函数调用

### 最小化import

import会增加header的大小，尽可能的最小化import， 将import放在.m, .c, cpp, .mm文件中
可以使用以下形式最小化

```objective-c
#import <Foundation/Foundation>
@class EOCEmployer;

@interface EOCPerson: NSObject
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, strong) EOCEmployer *employer;
@end
```

而在EOCPerson.m文件中

```objective-c
#import "EOCPerson.h"
#import "EOCEmployer.h"

@implementation EOCPerson
//Implementation of methods
@end
```

对于protocol， 如果不向外暴露的话， 可以考虑在.m文件中实现

### 优先使用字面量

```objective-c
NSNumber *someNumber = [NSNumber numberWithInt: 1];
//but this is better
NSNumber *someNumber = @1;
```

### 优先使用类型常量而不是宏

优先把常量声明在.m中, .h文件可以通过**_extern_**引入

```objective-c
//EOCLoginManager.h
#import <Foundation/Foundation.h>
extern NSString *const EOCLoginManagerDidLoginNotification;

@interface EOCLoginManager: NSObject
- (void) login;
@end

///EOCLoginManager.m
#import "EOCLoginManager.h"

NSString *const EOCLoginManagerDidLoginNotification = @"EOCLoginManagerDidLoginNotification";

@implementation EOCLoginManager

-(void) login{

}

-(void) p_didLogin{
    [[NSNotificationCenter defaultCenter]
        postNotificationName: EOCLoginManagerDidLoginNotification
            object: nil];
}
@end
```

### 使用枚举来管理状态

NS_ENUM 在是否是C++环境下有不同的定义
C++环境下，两个枚举按位或所得值将会是NSUInteger， 而不是枚举本身
同时不允许隐式转换成枚举
在需要操作枚举值的情况下，应使用NS_OPTIONS

```objective-c
typedef NS_ENUM(NSUInteger, EOCConnectionState) {
    EOCConnectionStateDisconnected,
    EOCConnectionStateConnecting,
    EOCConnectionStateConnected,
};

switch(_currentState){
    EOCConnectionStateDisConnected:
        //Handle disconnected state
        break;
    EOCConnectionStateConnecting:
        //Handle connecting state
        break;
EOCConnectionStateConnected:
        //Handle connected state
        break;
}
```

## Objects, Messaging & Runtime

### properties

尽可能使用getter和setter来访问instance variable 而不是通过直接访问
通过增加@synthesize 关键字可以重命名getter跟setter方法构造的方法名

```objective-c
@implementation EOCPerson
@synthesize firstName = _myFirstName;
@synthesize lastName = _myLastName;
```

使用@dynamic关键字可以是编译器不生成实例变量来支撑属性， 并且getter和setter也不生成
在CoreData的NSManagedObject中还是比较常用的

```objective-c
@interface EOCPerson: NSManagedObject
@property NSString *firstName;
@property NSString *lastName;
@end

@implementation EOCPerson
@dynamic firstName, lastName;
@end
```

### 尽量直接访问变量，通过setter设置变量(内部相互调用下)
