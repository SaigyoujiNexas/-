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

* madvise: Tell the OS how you expect to read certain pages.
* mlock: Tell the OS that memory ranges cannot be paged out.
* msync: Tell the OS to flush memory rages out to disk.

![image-20220424200702334](https://s2.loli.net/2022/04/24/SPHQIcUrokmAx1C.png)

# Problem 1: How the DBMS represents the database in files on disk.

 the DBMS stores a database as one or more files on disk.**The OS doesn't know anything about the contents of these files**

the **storage manager**  is responsible for maintaining a database's files.(Some do their own scheduling for reads and writes to improve spatial and temporal locality of pages.)

It organizes the files as a collection of pages.

* Tracks data read/written to pages.
* Tracks the available space.

 A **page** is a fixed-size block of data.

* It can contain tuples, meta-data, indexes, log records...
* Most systems do not mix page types.
* Some systems require a page to be self-contained.

Each page is given a unique identifier

* The DBMS uses an indirection layer to map page ids to physical locations.

There are three different notions of "pages" in a DBMS:

* Hardware Page(usually 4KB)
* OS Page(usually 4KB)
* Database Page(512B-16KB)

by hardware page, we mean at what level the device can guarantee a "failsafe write"

A **heap file** is am unordered collection of pages where tuples that are stored in random order.

* Create/Get/Write/Delete Page
* Must also support iterating over all pages.

Need meta-data to keep track of what pages exist and which ones have free space.

Two ways to represent a heap file:

* Linked List
* Page Directory

Second is a best solution project.

## Heap File: Linked List

Maintain a **header page** at the beginning of the file that stores two pointers:

* HEAD of the **free page list**
* HEAD of the **data page list**

Each page keeps track of the number of free slots in itself.

## Heap File: Page Directory

![image-20220424211358334](https://s2.loli.net/2022/04/24/JmMoEqk6RGzYdFc.png)

Every page contains a **header** of meta-data about the page's contents.

* Page size
* Check sum
* DBMS Version
* Transaction Visibility
* Compression Information

Some systems require pages to be **self-contained(e.g. Oracle)**

![image-20220424212148202](https://s2.loli.net/2022/04/24/Av59kmZobJ4SHRP.png)

![image-20220424212305250](https://s2.loli.net/2022/04/24/R1amtn9DKw7YOCZ.png)

But this design is really suck.

if i delete the tuple2, and insert the tuple 4, then, what position is tuple 4 to  save in?

to tranverse the page?

## Slotted Pages

![image-20220424212809204](https://s2.loli.net/2022/04/24/bco9Aae8I1HiXzF.png)

The DBMS needs a way to keep track of individual tuples.

Each tuple is assigned a unique **record identifier**

* Most common: page_id + offset/slot
* Can also contain file location info

An application **cannot** rely on these ids to mean anything.

## Tuple Header

![image-20220424215708772](https://s2.loli.net/2022/04/24/pid5fw7kXgvZqRG.png)

![image-20220424215752735](https://s2.loli.net/2022/04/24/KEjfgIvFPoAwLuT.png)

Can physically denormalize(e.g., "prejoin") related tuples and store them together in the same page.

* Potentially reduces the amount of I/O for common workload patterns.
* Can make updates more expensive.

### Normally:

![image-20220424220143800](https://s2.loli.net/2022/04/24/AydqYVhfse8C4Si.png)

### Denormalized tuple data:

![image-20220424220605297](https://s2.loli.net/2022/04/24/CtQ9z12Y8JawxyK.png)