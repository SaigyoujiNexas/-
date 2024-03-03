@[TOC](本地方法)

# 从Java程序调用C函数

```java
/**
 * @version 1.11 2007-10-26
 * @author Cay Horstmann
 */

 class HelloNative{
    
    public static native void greeting();
    public static void main(String...args)
     {
         greeting();
     }
 }
```

对于编译生成的class文件， 为了实现本地代码，命名规则如下：

1. 使用完整的Java方法名例如HelloNative.greeting, 如果该类属于某个包，则还要加上包名，例如com.horstmann.HelloNative.greeting
2. 用下划线替换所有的句号并加上Java_前缀，例如Java_HelloNative_greeting
3. 如果含有非ASCII字母或数字， 用_0xxxx来替代， xxxx是该字符的Unicode值的4个十六进制数序列

tips：若重载了本地方法则应该在名称后面追加两个下划线再加上已编码的参数类型

使用

```shell
javac -h . HelloNative.java
```

随后实现函数

```c
/*
    @version 1.10 1997-07-01
    @author Cay Horstmann
*/
#include"HelloNative.h"
#include<stdio.h>

JNIEXPORT void JNICALL Java_HelloNative_greeting(JNIEnv*env, jclass thiz)
{
    printf("Hello Native World!\n");
}
```

Linux下gcc编译:

```shell
 gcc -fPIC -I /usr/lib/jvm/java-17-openjdk-amd64/include -I /usr/lib/jvm/java-17-openjdk-amd64/include/linux -shared
 -o libHelloNative.so HelloNative.c
```

这里java安装目录视实际安装位置而定

追加初始化操作

```java
/**
 * @version 1.11 2007-10-26
 * @author Cay Horstmann
 */

 class HelloNative{
    
    public static native void greeting();
    public static void main(String...args)
     {
         greeting();
     }
     static{
         System.loadLibrary("HelloNative");
     }
 }
```



# 数值参数与返回值

```java
/**
 * @version 1.10 1997-07-01
 * @author Cay Horstmann
 */
class Printf1{
    public static native int print(int width, int precision, double x);
    static
    {
        System.loadLibrary("Printf1");
    }
}
```

```c
/**
 * @file Printf1.c
 * @author Cay Horstmann
 * @brief 
 * @version 1.10 1997-07-01
 * @date 2022-06-07
 * 
 * @copyright Copyright (c) 2022
 * 
 */
#include"Printf1.h"
#include<stdio.h>
JNIEXPORT jint JNICALL Java_Printf1_print(JNIEnv* env, jclass cl, jint width, jint precision, jdouble x)
{
    char fmt[30];
    jint ret;
    sprintf(fmt, "%%%d.%df", width, precision);
    ret = printf(fmt, x);
    fflush(stdout);
    return ret;
}
```

```java
public class Printf1Test {
    public static void main(String ...args)
    {
        int count = Printf1.print(8, 4, 3.14);
        count += Printf1.print(8, 4, count);
        System.out.println();
        for(int i = 0; i < count; i++)
        {
            System.out.print("-");
        }
        System.out.println();
    }
    
}

```

# 字符串参数

Java使用UTF-16编码点的序列作为字符串， 而C使用以null结尾的字节序列， JNI有两组操作字符串的函数， 一组把Java字符串转换成“modified UTF-8”字节序列， 另一个转换为jchar数组

```c
JNIEXPORT jstring JNICALL Java_HelloNative_getGreeting(JNIEnv * env, jclass cl)
{
    jstring jstr;
    char greeting[] = "Hello, Native World\n";
    jstr = (*env)-> NewStringUTF(env, greeting);
    return str;
}
```

env是一个指向函数指针表的指针, 必须在每个JNI调用前加上(*env)->， 以便解析对函数指针的引用。

```java
/**
 * @version 1.10 1997-07-01
 * @author Cay Horstmann
 */
public class Printf2 {
    public static native String sprintf(String format, double x);
    static{
        System.loadLibrary("Printf2");
    }
}

```

```c
/**
 * @file Printf2.c
 * @author Cay Horstmann
 * @brief 
 * @version 1.10
 * @date 1997-07-01
 * 
 * @copyright Copyright (c) 2022
 * 
 */

#include"Printf2.h"
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<float.h>

/**
 * @param format a string containing a printf format specifier
 * (such as "%8.2f"), Substrings "%%" are skipped.
 * @return a pointer to the format specifier (skipping the '%')
 * or NULL if there was not a unique format specifier.
 * 
 */
char * find_format(const char format[])
{
    char *p;
    char *q;
    p = strchr(format, '%');
    while(p != NULL && *(p + 1) == '%') /*ship %%*/
        p = strchr(p + 2, '%');
    if(p == NULL) return NULL;
    /* now check that % is unique*/
    p++;
    q = strchr(p, '%');
    while(q != NULL && *(q + 1) == '%') /*skip %% */
        q = strchr(q + 2, '%');
    if(q != NULL) return NULL;  /* % not unique */
    q = p + strspn(p, " -0+#"); /* skip past flags */
    q += strspn(q, "0123456789");   /*ship past field width */
    if(*q =='.'){
        q++;
        q += strspn(q, "0123456789");
    }
    /* skip past field width */
    if(strchr("eEfFgG", *q) == NULL) return NULL;
    /* skip past precision */
    return p;   
}

JNIEXPORT jstring JNICALL Java_Printf2_sprintf(JNIEnv * env, jclass cl, jstring format, jdouble x){
    const char * cformat;
    char * fmt;
    jstring ret;

    cformat =(*env)->GetStringUTFChars(env, format, NULL);
    fmt = find_format(cformat);
    if(fmt == NULL)
    ret = format;
    else{
        char * cret;
        int width = atoi(fmt);
        if(width == 0) width = DBL_DIG + 10;
        cret = (char *)malloc(strlen(cformat) + width);
        sprintf(cret, cformat, x);
        ret = (*env)->NewStringUTF(env, cret);
        free(cret);
    }
    (*env)->ReleaseStringUTFChars(env, format, cformat);
    return ret;
}

```



```java
/**
 * @version 1.10 1997-07-01
 * @author Cay Horstmann
 */
public class Printf2Test {
    public static void main(String...args)
    {
        double price = 44.95;
        double tax = 7.75;
        double amountDue = price * (1 + tax / 100);
        String s = Printf2.sprintf("Amount due = %8.2f", amountDue);
        System.out.println(s);
    }
}

```

# 访问域

## 访问实例域

对于Java方法

```java
public void raiseSalary(double byPercent)
{
    salary *= 1 + byPercent / 100;
}
```

重写成本地方法后为

```c
JNIEXPORT void JNICALL Java_Employee_raiseSalary(JNIEnv *, jobject, jdouble);
```

第二个参数变为jobject， 他和this引用等价。

静态方法得到类的引用，非静态得到this参数对象的引用。

获得各种类型的通用语法为

```c
x = (*env)->GetXxxxField(env, this_obj, fieldId);
(*env)->SetXxxxxField(env, this_obj, fieldId, x);
```

fieldID标识结构中的一个域， 为了获得fieldID首先要获得一个表示类的值

```c
jclass class_Employee = (*env)->GetObjectClass(env, this_obj);
```

FindClass函数可以以字符串形式来指定类名

```c
jclass class_String = (*env)->FindClass(env, "java/lang/String");
```

之后使用GetFieldID来获得fieldID

```c
jfield id_salary = (*env)->GetFieldID(env, class_Employee, "salary", "D");
```

```java
/**
 * @version 1.10 1999-11-13
 * @author Cay Horstmann
 */
public class Employee {
    private String name;
    private double salary;

    public native void raiseSalary(double byPercent);

    public Employee(String n, double s)
    {
        name = n;
        salary = s;
    }
    public void print(){
        System.out.println(name + " " + salary);
    }
    static{
        System.loadLibrary("Employee");
    }
}

```

```c
/**
 * @file Employee.c
 * @author Cay Horstmann
 * @brief 
 * @version 1.10
 * @date 2022-06-08
 * 
 * @copyright Copyright (c) 2022
 * 
 */
#include"Employee.h"
#include<stdio.h>

JNIEXPORT void JNICALL Java_Employee_raiseSalary(
    JNIEnv * env, jobject this_obj, jdouble byPercent){
        /* get class */
        jclass class_Employee = (*env)->GetObjectClass(env, this_obj);

        /* get the field ID */
        jfieldID id_salary = (*env)->GetFieldID(env, class_Employee, "salary", "D");

        /* get the field value */
        jdouble salary = (*env)->GetDoubleField(env, this_obj, id_salary);
        
        salary *= 1 + byPercent/ 100.0;
        /* set the field value */
        (*env)->SetDoubleField(env, this_obj, id_salary, salary);
    }
```

```java
/**
 * @version 1.11 2018-05-01
 * @author Cay Horstmann
 */
public class EmployeeTest {
    public static void main(String[] args) {
        var staff = new Employee[3];
        staff[0] = new Employee("Harry Hacker", 35000);
        staff[1] = new Employee("Carl Cracker", 75000);
        staff[2] = new Employee("Tony Tester", 38000);

        for(Employee e: staff)
            e.raiseSalary(5);
        for(Employee e: staff)
            e.print();
    }
}

```

## 访问静态域

访问静态域使用GetStaticFieldID和GetStaticXxxField/SetStaticXxxField函数

```c
jclass class_System = (*env)->FindClass(env, "java/lang/System");

/* get the field ID */
jfieldID id_out = (*env)->GetStaticFieldID(env, class_System, "out", "Ljava/io/PrintStream;");

/* get the field value */
jobject obj_out = (*env)->GetStaticObjectField(env, class_System, id_out);
```

# 编码签名

B: byte

C: char

D: double

F: float

I: int

J:long

Lclassname; : 类的类型

S: short

V: void

Z: boolean

描述数组类型使用[

字符串数组: [Ljava/lang/String;

float\[][] : [[F

一个接收两个整型返回一个整型的方法编码: (II)I

如构造器： Employee(java.lang.String, double, java.util.Date)

签名为: (Ljava/lang/String;DLjava/util/Date;)V

可以使用带有选项-s的javap命令来从类文件中产生方法签名

```shell
javap -s -private Employee
```

# 调用Java方法

使用如下方法可以调用Java方法

```c
(*env)->CallXxxxMethod(env, implicit parameter, methodID, explicit parameters)
```



```java
import java.io.*;
/*
 * @version 1.10 1997-07-01
 * @author Cay Horstmann
 */
public class Printf3 {
    public static native void fprint(PrintWriter out, String format, double x);

    static{
        System.loadLibrary("Printf3");
    }
}

```

```c
/**
 * @file Printf3.c
 * @author Cay Horstmann
 * @brief 
 * @version 1.10
 * @date 2022-06-08
 * 
 * @copyright Copyright (c) 2022
 * 
 */
#include"Printf3.h"
#include<string.h>
#include<stdlib.h>
#include<float.h>
/**
 * @param format a string containing a printf format specifier
 * (such as "%8.2f"). Substrings "%%" are skipped.
 * @return a pointer to the format specifier (skipping the '%')
 * or NULL if there was not a unique format specifier
 * 
 */
char * find_format(const char format[])
{
    char * p;
    char *q;

    p = strchr(format, '%');
    while(p != NULL && *(p + 1) == '%') /* skip %% */
        p = strchr(p + 2, '%');
    if(p == NULL) return NULL;
    /* now check that % is unique */
    p++;
    q = strchr(p, '%');
    while(q != NULL && *(q + 1) == '%') /* skip %% */
        q = strchr(q + 2, '%');
    if(q != NULL)return NULL;   /* % not unique */
    q = p + strspn(p, " -0+#"); /* skip past flags */
    q += strspn(q, "0123456789");   /*skip past field width */
    if(*q == '.') {q++; q +=strspn(q, "0123456789");}
    /*skip past precision */
    if(strchr("eEfFgG", *q) == NULL) return NULL;
    /* not a floating-point format */
    return p; 
}
JNIEXPORT void JNICALL Java_Printf3_fprint(JNIEnv * env, jclass cl, jobject out, jstring format, jdouble x)
{
    const char * cformat;
    char * fmt;
    jstring str;
    jclass class_PrintWriter;
    jmethodID id_print;

    cformat = (*env)->GetStringUTFChars(env, format, NULL);
    fmt = find_format(cformat);
    if(fmt == NULL)
        str = format;
    else{
        char * cstr;
        int width = atoi(fmt);
        if(width == 0) width = DBL_DIG + 10;
        cstr = (char *) malloc(strlen(cformat) + width);
        sprintf(cstr, cformat, x);
        str = (*env)->NewStringUTF(env, cstr);
        free(cstr);
    }
    (*env)->ReleaseStringUTFChars(env, format, cformat);

    /* now call ps.print(str) */

    /* get the class */
    class_PrintWriter = (*env)->GetObjectClass(env, out);

    /* get the methodID */
    id_print = (*env)->GetMethodID(env, class_PrintWriter, "print", "(Ljava/lang/String;)V");

    /* call the method */
    (*env)->CallVoidMethod(env, out, id_print, str);
}
```

```java
import java.io.*;
/**
 * @version 1.11 2018-05-01
 * @author Cay Horstmann
 */
public class Printf3Test {
    public static void main(String[] args) {
        double price = 44.95;
        double tax = 7.75;
        double amountDue = price * (1 + tax / 100);
        var out = new PrintWriter(System.out);
        Printf3.fprint(out, "Amount due = %8.2f\n", amountDue);
        out.flush();
    }
}

```

## 静态方法

用GetStaticMethodID和CallStaticXxxxMethod函数。

当调用方法时提供类对象而不是参数对象。

```c
jclass class_System = (*env)->FindClass(env, "java/lang/System");
jmethodID id_getProperty = (*env)->GetStaticMethodID(env, class_System, "getProperty",
  "(Ljava/lang/String;)Ljava/lang/String;");
jobject obj_ret = (*env)->CallStaticObjectMethod(env, class_System,id_getProperty, (*env)->NewStringUTF(env, "java.class.path"));

jstring str_ret = (jstring) obj_ret;
```



## 构造器

本地方法通过调用构造器创建Java对象， 调用NewObject来调用构造器

```c
jobject obj_new = (*env)->NewObject(env, class, methodID, construction parameters);
```

```c
const char[] fileName = "...";
jstring str_fileName = (*env)->NewStringUTF(env, fileName);
jclass class_FileOutputStream = (*env)->FindClass(env, "java/io/FileOutputStream");
jmethodID id_FileOutputStream = (*env)->GetMethodID(env, class_FileOutputStream, "<init>", "(Ljava/lang/String;)V");
jobject obj_stream = (*env)->NewObject(env, class_FileOutputStream, id_FileOutputStream, str_fileName);
```



CallNonvirtualXxxxMethod函数将调用指定的类中指定的版本的方法。



# 访问数组元素

GetArrayLength返回数组的长度

```c

jarray array = ...;
jsize length = (*env)->GetArrayLength(env, array);
```



```c
jdoubleArray array_a = ....;
double scaleFactor = ....;
double * a = (*env)->GetDoubleArrayElements(env, array_a, NULL);
for(int i = 0; i < (*env)->GetArrayLength(env, array_a); i++)
    a[i] = a[i] * scaleFactor;
(*env)->ReleaseDoubleArrayElements(env, array_a, a, 0);
```

如果要访问一个大数组的多个元素， 可以用GetXxxxArrayRegion和SetXXXArrayRegion方法

NewXXXArray在本地方法中创建新的Java数组

```c
jclass class_Employee = (*env)->FindClass(env, "Employee");
jobjectArray array_e = (*env)->NewObjectArray(env, 100, class_Employee, NULL);
```



# 错误处理

```java
import java.io.*;
/*
 * @version 1.10 1997-07-01
 * @author Cay Horstmann
 */
public class Printf4 {
    public static native void fprint(PrintWriter ps, String format, double x);

    static{
        System.loadLibrary("Printf4");
    }
}

```

```java
/**
 * @file Printf3.c
 * @author Cay Horstmann
 * @brief 
 * @version 1.10
 * @date 2022-06-08
 * 
 * @copyright Copyright (c) 2022
 * 
 */
#include"Printf4.h"
#include<string.h>
#include<stdlib.h>
#include<float.h>
/**
 * @param format a string containing a printf format specifier
 * (such as "%8.2f"). Substrings "%%" are skipped.
 * @return a pointer to the format specifier (skipping the '%')
 * or NULL if there was not a unique format specifier
 * 
 */
char * find_format(const char format[])
{
    char * p;
    char *q;

    p = strchr(format, '%');
    while(p != NULL && *(p + 1) == '%') /* skip %% */
        p = strchr(p + 2, '%');
    if(p == NULL) return NULL;
    /* now check that % is unique */
    p++;
    q = strchr(p, '%');
    while(q != NULL && *(q + 1) == '%') /* skip %% */
        q = strchr(q + 2, '%');
    if(q != NULL)return NULL;   /* % not unique */
    q = p + strspn(p, " -0+#"); /* skip past flags */
    q += strspn(q, "0123456789");   /*skip past field width */
    if(*q == '.') {q++; q +=strspn(q, "0123456789");}
    /*skip past precision */
    if(strchr("eEfFgG", *q) == NULL) return NULL;
    /* not a floating-point format */
    return p; 
}
JNIEXPORT void JNICALL Java_Printf4_fprint(JNIEnv * env, jclass cl, jobject out, jstring format, jdouble x)
{
    const char * cformat;
    char * fmt;
    jstring str;
    jclass class_PrintWriter;
    jmethodID id_print;
    char * cstr;
    int width;
    int i;

    if(format == NULL)
    {
        (*env)->ThrowNew(
            env,
            (*env)->FindClass(env, "java/lang/NullPointerException"),
            "Printf4.fprint: format is null"
        );
    }

    cformat = (*env)->GetStringUTFChars(env, format, NULL);
    fmt = find_format(cformat);
    if(fmt == NULL)
    {
        (*env)->ThrowNew(env,
        (*env)->FindClass(env, "java/lang/IllegalArgumentException"),
        "Printf4.fprint: format is invalid");
        return;
    }
        width = atoi(fmt);
        if(width == 0) width = DBL_DIG + 10;
        cstr = (char *) malloc(strlen(cformat) + width);
        if(cstr == NULL)
        {
            (*env)->ThrowNew(env,
            (*env)->FindClass(env, "java/lang/OutOfMemoryError"),
            "Printf4.fprint: malloc failed!");
            return;
        }
        sprintf(cstr, cformat, x);
        (*env)->ReleaseStringUTFChars(env, format, cformat);

        /* now call ps.print(str) */

    /* get the class */
    class_PrintWriter = (*env)->GetObjectClass(env, out);

    /* get the methodID */
    id_print = (*env)->GetMethodID(env, class_PrintWriter, "print", "(C)V");

    /* call the method */
    for(i = 0; cstr[i] != 0 && !(*env)->ExceptionOccurred(env); i++)
        (*env)->CallVoidMethod(env, out, id_print, cstr[i]);
    free(cstr);
}
```

```java
import java.io.*;
/**
 * @version 1.11 2018-05-01
 * @author Cay Horstmann
 */
public class Printf4Test {
    public static void main(String[] args) {
        double price = 44.95;
        double tax = 7.75;
        double amountDue = price * (1 + tax/ 100);
        var out = new PrintWriter(System.out);
        /* This call will throw an exception--note the %% */
        Printf4.fprint(out, "Amount due = %%8.2f\n", amountDue);
        out.flush();
    }
}
```

# 使用调用API

调用API所需的基本代码

```java
JavaVMOption option[1];
JavaVMInitArgs vm_args;
JavaVM * jvm;
JNIEnv * env;

options[0].optionString = "-Djava.class.path=.";
memset(&vm_args, 0, sizeof(vm_args));
vm_args.version = JNI_VERSION_1_2;
vm_args.nOption = 1;
vm_args.options = options;

JNI_CreateJavaVM(&jvm, (void**)&env, &vm_args);
```

以下是测试程序， 因为是在linux下，windows的兼容性我就懒的写了（lj微软）

```c
/**
 * @file InvocationTest.c
 * @author Cay Horstmann
 * @brief 
 * @version 0.1
 * @date 2022-06-08
 * 
 * @copyright Copyright (c) 2022
 * 
 */
#include<string.h>
#include<jni.h>
#include<stdlib.h>

#ifdef _WINDOWS
#include<windows.h>
static HINSTANCE loadJVMLibrary(void);
typedef jint(JNICALL * CreateJavaVM_t)(JavaVM**, void **, JavaVMInitArgs *);

#endif

int main()
{
    JavaVMOption options[2];
    JavaVMInitArgs vm_args;
    JavaVM * jvm;
    JNIEnv * env;
    long status;

    jclass class_Welcome;
    jclass class_String;
    jobjectArray args;
    jmethodID id_main;

    #ifdef _WINDOWS
    HINSTANCE hjvmlib;
    CreateJavaVM_t createJavaVM;
    #endif
    options[0].optionString = "-Djava.class.path=.";

    memset(&vm_args, 0, sizeof(vm_args));
    vm_args.version = JNI_VERSION_1_6;
    vm_args.nOptions = 1;
    vm_args.options = options;

    #ifdef _WINDOWS
    hjvmlib = loadJVMLibrary();
    createJavaVM = (CreateJavaVM_t) GetProcAddress(hjvmlib, "JNI_CreateJavaVM");
    status = (*createJavaVM)(&jvm, (void **)&env, &vm_args);
    #else
    status = JNI_CreateJavaVM(&jvm, (void**)&env, &vm_args);
    #endif

    if(status == JNI_ERR)
    {
        fprintf(stderr, "Error creating VM\n");
        return 1;
    }
    class_Welcome = (*env)->FindClass(env, "Welcome");
    id_main = (*env)->GetStaticMethodID(env, class_Welcome, "main", "([Ljava/lang/String;])V");

    class_String = (*env)->FindClass(env, "java/lang/String");
    args = (*env)->NewObjectArray(env, 0, class_String, NULL);
    (*env)->CallStaticVoidMethod(env, class_Welcome, id_main, args);

    (*jvm)->DestroyJavaVM(jvm);
}

```

```java
/**
 * This program displays a greeting for the reader.
 * @version 1.30 2014-02-27
 * @author Cay Horstmann
 */
public class Welcome
{
   public static void main(String[] args)
   {
      String greeting = "Welcome to Core Java!";
      System.out.println(greeting);
      for (int i = 0; i < greeting.length(); i++)
         System.out.print("=");
      System.out.println();
   }
}

```

