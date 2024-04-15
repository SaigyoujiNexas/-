@[TOC](Database Storage)

The DBMS assumes that the primary storage location of the database is on non_volatile disk.

The DBMS's components manage the movement of data between non-volatile and volatile storage.

![image-20220424192424301](https://s2.loli.net/2022/04/24/zwPKRmZficyeJls.png)

![image-20220424192944224](https://s2.loli.net/2022/04/24/MxqGAr5db1Zlsny.png)

# System Design Goals

Allow the DBMS to manage databases that exceed the amount of memory available.

Reading/Writing to disk is expensive, so it must be managed carefully to avoid large stalls and performance degradation.

![image-20220424195659381](https://s2.loli.net/2022/04/24/kSYIPCvzoFuZhjl.png)

Multiple threads to access the mmap files to hide page fault stalls.

This works good enough for read-only access. It is complicated when there are multiple writers.

There are some solution to this problem:

- madvise: Tell the OS how you expect to read certain pages.
- mlock: Tell the OS that memory ranges cannot be paged out.
- msync: Tell the OS to flush memory rages out to disk.

![image-20220424200702334](https://s2.loli.net/2022/04/24/SPHQIcUrokmAx1C.png)

# Problem 1: How the DBMS represents the database in files on disk.

the DBMS stores a database as one or more files on disk.**The OS doesn't know anything about the contents of these files**

the **storage manager** is responsible for maintaining a database's files.(Some do their own scheduling for reads and writes to improve spatial and temporal locality of pages.)

It organizes the files as a collection of pages.

- Tracks data read/written to pages.
- Tracks the available space.

A **page** is a fixed-size block of data.

- It can contain tuples, meta-data, indexes, log records...
- Most systems do not mix page types.
- Some systems require a page to be self-contained.

Each page is given a unique identifier

- The DBMS uses an indirection layer to map page ids to physical locations.

There are three different notions of "pages" in a DBMS:

- Hardware Page(usually 4KB)
- OS Page(usually 4KB)
- Database Page(512B-16KB)

by hardware page, we mean at what level the device can guarantee a "failsafe write"

A **heap file** is am unordered collection of pages where tuples that are stored in random order.

- Create/Get/Write/Delete Page
- Must also support iterating over all pages.

Need meta-data to keep track of what pages exist and which ones have free space.

Two ways to represent a heap file:

- Linked List
- Page Directory

Second is a best solution project.

## Heap File: Linked List

Maintain a **header page** at the beginning of the file that stores two pointers:

- HEAD of the **free page list**
- HEAD of the **data page list**

Each page keeps track of the number of free slots in itself.

## Heap File: Page Directory

![image-20220424211358334](https://s2.loli.net/2022/04/24/JmMoEqk6RGzYdFc.png)

Every page contains a **header** of meta-data about the page's contents.

- Page size
- Check sum
- DBMS Version
- Transaction Visibility
- Compression Information

Some systems require pages to be **self-contained(e.g. Oracle)**

![image-20220424212148202](https://s2.loli.net/2022/04/24/Av59kmZobJ4SHRP.png)

![image-20220424212305250](https://s2.loli.net/2022/04/24/R1amtn9DKw7YOCZ.png)

But this design is really suck.

if i delete the tuple2, and insert the tuple 4, then, what position is tuple 4 to save in?

to tranverse the page?

## Slotted Pages

![image-20220424212809204](https://s2.loli.net/2022/04/24/bco9Aae8I1HiXzF.png)

The DBMS needs a way to keep track of individual tuples.

Each tuple is assigned a unique **record identifier**

- Most common: page_id + offset/slot
- Can also contain file location info

An application **cannot** rely on these ids to mean anything.

## Tuple Header

![image-20220424215708772](https://s2.loli.net/2022/04/24/pid5fw7kXgvZqRG.png)

![image-20220424215752735](https://s2.loli.net/2022/04/24/KEjfgIvFPoAwLuT.png)

Can physically denormalize(e.g., "prejoin") related tuples and store them together in the same page.

- Potentially reduces the amount of I/O for common workload patterns.
- Can make updates more expensive.

### Normally:

![image-20220424220143800](https://s2.loli.net/2022/04/24/AydqYVhfse8C4Si.png)

### Denormalized tuple data:

![image-20220424220605297](https://s2.loli.net/2022/04/24/CtQ9z12Y8JawxyK.png)

## Log-Structured file organization

一种替换在pages中保存tuples的方式为DBMS只保存日志记录(log record)

![image-20240415001740919](https://s2.loli.net/2024/04/15/R8Qr47YmbsTc9h6.png)

## Tuple Storage

- INTEGER/BIGINT/SMALLINT/TINYINT 为C/C++数据大小即可
- FLOAT/REAL ---IEEE-754 标准 NUMERIC/DECIMAL 定点浮点数
- VARCHAR/VARBINARY/TEXT/BLOB header保存长度， 后面存内容
- TIME/DATE/TIMESTAMP 64位整数

### Large Value

大多数DBMS不允许tuple超过1page

为保存超过1page的数据， DBMS使用overflow storage pages

- Postgres： TOAST (>2KB)
- MySQL: Overflow( > 1/2 size of page)
- SQL Server: Overflow( > size of page)

![image-20240415002840571](https://s2.loli.net/2024/04/15/pmhaAoB8lTWeVjN.png)

External Value Storage

一些系统使用BLOB类型在外部文件中保存大型数据

- Oracle： BFILE
- Microsoft： FILESTREAM

DBMS无法直接管理这些内容

![image-20240415003133669](https://s2.loli.net/2024/04/15/qszyEprP9kIRGHf.png)

## 系统目录

- 将元组信息抽象
- 在引导列表使用特定编码（INFORMATION_SCHEMA）

**关系模型由于没有将全部的tuple表存在一个page中，在某些情况下工作性能不是很好 **

## OLTP

即On-line Transaction Processing:

通常是简单的读取/添加/更新值

![image-20240415004206893](https://s2.loli.net/2024/04/15/iacoezjPZI2CFTf.png)

## OLAP

On-line Analytical Processing:

复杂的查询， 读入大量数据

![image-20240415004341620](https://s2.loli.net/2024/04/15/lI2oiTLFwD6O8Wn.png)

![image-20240415004408326](https://s2.loli.net/2024/04/15/Rhct2sj1paSGJNP.png)

对于OLTP， NOSQL比较好用， 例如Mongo， Redis

对于OLAP， NewSQL比较好用， 不过现在比较初始

## 存储模型

### 行存储

也称为NSM(N-ARY STORAGE MODEL)

![image-20240415004639542](https://s2.loli.net/2024/04/15/MSLFDqeC3rsa1mT.png)

优点：

- 增删查快
- 对于需要一整个tuple的场景性能非常好

缺点： 查找一次会读取一整行， 但是有时只需要一辆列上的数据

### 列存储

一个page只存储一列的数据

![image-20240415004952306](https://s2.loli.net/2024/04/15/Y6g4E7FRzIJAXZd.png)

对于tuple中值的定位

- 固定column的长度

- 保存在tuple上的id

大多是都用第一种

![image-20240415005203005](https://s2.loli.net/2024/04/15/MqP3E86Cyxu5He1.png)

优点：

- 避免IO浪费

- 更好的查询处理和数据压缩

缺点：

由于一个tuple的column在不同page上，查询，插入，更新， 删除的速度降低

现在主流数据库都用的列存储

对于特殊场景

- OLTP -> 行存储
- OLAP -> 列存储
