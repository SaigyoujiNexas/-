 ## Android Task

##  设定Activity 启动模式的两种方式



1. 使用清单文件

   ```xml
   <actvity android.name=".MainActivity"
            android:launchMode="..."
   />
   ```

   startard: 每次启动都创建实例

   singleTop：若存在实例在栈顶， 则重用该实例， 并调用onNewIntent方法

   singleTask: 在同一个任务栈只有一个实例

   ![image-20220329204606318](https://s2.loli.net/2022/03/29/arzpoByVGjsFubM.png)

2. intent设定

# Intent

Android 平台采用“松散协同配合”理念进行设计， 淡化了**进程**的概念。

Android 引入了"Intent"组件作为信使， 来完成进程间通信。

## Intent 的 Action

Action： 代表要执行的操作(ACTION_VIEW; ACTION_DIAL; ACTION_EDIT)

## Data

```kotlin
intent.setAction(Intent.ACTION_CALL)
intent.setData(Uri.parse("tel:12121"))

startActivity(intent)
```

## Type

表示Action要处理的数据的类型， 通常为MIME类型， 使用Intent.setType()方法。

**Type与Data通常互斥，设置一个会导致另一个清空， 若要同时设置，使用setDataAndType（）

```kotlin
val intent = Intent(Intent.ACTION_VIEW)
intent.setDataAndType("file:///sdcard/image1.jpg", "image/jpg")
```

## Category

表示Intent所属的种类，android.intnet.category.LAUNCHER指定App初始启动的Activity是哪个。

## Component, Extras和Flags

### Component

指明希望启动的目标组件信息。可以通过Intent.setComponent方法利用类名进行设置， 也可以通过Intent.setClass方法利用Class对象设置

### Extras

其实就是Bundle对象

### Flags

指定目标组件的启动模式。

## Intent Filter

通常在AndroidManifest.xml文件中设置， 是< activity >的子元素

**Intent Filter描述了一个组件愿意并且能够接受什么样的Intent对象**

其中Action主要用于向Android系统表明本组件能“做哪些事”或“响应哪种类型的消息”。

```kotlin
val intent = Intent()
intnet.setAction("cn.edu.bit.cs.powersms")
...
startActivity(intent)
```

 