# SQL语句的分类

## DQL

数据查询语言（凡是带有select关键字的都是DQL）

## DML

数据操作语言（凡是对表中数据进行增删改的都是DML）

insert update 和 delete

## DDL

数据定义语言（凡是带有create, drop, alter 的都是DDL）

create : 新建， 等同于增

drop： 删除

alter： 修改

这个增删改主要对表结构进行修改

## TCL

事务控制语言， 包括：

- 事务提交： commit
- 事务回滚： rollback

## DCL

数据控制语言

例如： 授权qrant， 撤销权限revoke...

## 查看表的信息

使用desc命令( describe)

desc 表名

```
> desc dept;
```

# 常用命令

## 查看mysql版本

```
select version();
```

## 查看当前所在database

```java
select database();
```

**\c 可以用来终止命令**

## 退出

```
exit
```

# SQL 语句

## DQL

### 查询一个字段

select 字段名 from 表名；

### 查询多个字段

使用逗号隔开

```
select deptno, dname from dept;
```

### 查询所有字段

使用\* 号

**但是效率低， 可读性差**

### 给查询的列起别名

使用as关键字起别名

**只是将显示结果的列名显示为别名， 并不会修改列名**

```
select deptno, dname as deptname from dept;
```

可以省略as

```
select deptno, dname deptname form dept;
```

假设别名有空格

加个单引号括起来

```
 select deptno, dname as 'dept name' from dept;
```

**所有字符串中使用单引号是标准， 双引号不标准**

### 列参和数学计算

字段可以使用数学表达式

```
select ename, sal*12 from emp;
```

### 条件查询

| =                       | 等于                                                 |
| ----------------------- | ---------------------------------------------------- |
| <> 或 !=                | 不等于                                               |
| < , <=                  | 小于 小于等于                                        |
| >, >=                   | 大于 大于等于                                        |
| between ... and ...     | 两个值之间, 使用时需要遵循左小右大                   |
| is null ( is not null ) | 为空（不为空）                                       |
| and                     | 并且                                                 |
| or                      | 或                                                   |
| in                      | 包含， 相当于多个or                                  |
| not                     | 非                                                   |
| like                    | 模糊查询（%任意个字符匹配， \_下划线只匹配一个字符） |

```
select empno, ename from emp where sal = 800;
select empno, ename from emp where sal != 800;
select empno, ename from emp where sal < 2000;
select empno, ename from emp where sal <= 3000;
select empno, ename from emp where sal >3000;
select empno, ename, sal from emp where sal >= 3000;
select empno, ename, sal from emp where sal between 2450 and 3000;
select empno, ename, sal, comm from emp where comm is null;
select * from emp where job = 'MANAGER' and sal >= 2500;
select * from emp where job = 'MANAGER' or JOB = 'SALESMAN';
select * from emp where sal > 2500 and (deptno = 10 or deptno = 20);
select * from emp where job IN ('MANAGER', 'SALESMAN');
select * from emp where ENAME like '%AR%';
select * from emp where ENAME like '%\_%';
```

### 排序

```
select ename, sal from emp order by sal;
```

默认是升序

指定降序：

```
select ename, sal from emp order by sal desc;
```

指定升序：

```
select ename, sal from emp order by sal asc;
```

#### 多个字段排序

```
select ename, sal from emp order by sal asc, ename asc;
```

#### 根据字段位置排序

```
select ename, sal from emp order by 2;
```

### 数据处理函数

数据处理函数（单行处理函数）

#### 常见单行处理函数

lower 转换小写, upper 转化大写

```
select lower(ename) as ename from emp;
```

substr 取子串， 起始下标为1

```
select substr(ename, 1, 1) as ename from emp;
```

```
select ename from emp where substr(ename, 1, 1) = 'A';
```

```
select concat(lower(substr(ename, 1, 1)), substr(ename, 2, length(ename))) from emp;
```

length 求长度

trim 去除前后空格

```
select * from emp where ename = trim('     KING   ');
```

case ..when..then...then...when...then...else...end

```
select ename, job,sal as oldsal, (case job when 'MANAGER' then sal*1.1 when 'SALESMAN' then sal*1.5 else sal  end) as newsal from emp;
```

ifnull 可以将null 转换成一个特定的值

```
select ename, sal + ifnull(comm, 0) as salcomm from emp;
```

rand生成随机数

```
select rand() from emp;
```

```
select round(rand() * 100.0) from emp; // 100以内随机数
```

round 四舍五入

```
select round(1236.567, 0) as result from emp;		//0表示保留小数位
```

#### 分组函数（多行处理函数）

1. count 计数
2. sum 求和
3. avg 平均值
4. max 最大值
5. min 最小值

**若没有对数据分组， 默认整个表为一个组**

### DISTINCT

COUNT, SUM, AVG support DISTINCT
example: Get the number of unique students that have an "@cs" longin.

```sql
SELECT COUNT(DISTINCT login) FROM student WHERE login LIKE '@cs';
```

### GROUP BY

Project tuples into subsets and calculate aggregates against each subset.

### HAVING

Filters results based on aggregation computation.Like a WHERE clause for a GROUP BY

```sql
SELECT AVG(s.gpa) AS avg_gpa, e.cid FROM enrolled AS e, student AS s WHERE e.sid = s.sid
GROUP BY e.cid
HAVING avg_gpa > 3.9;
```

### String Operations

'%' Matches any substring (including empty strings)

'\_' Match any one character.

String Functions: SUBSTRING UPPER TRIM

### Data/Time Operations

example: Get the day between spcified two date.

```sql
//get Current date.
SELECT CURRENT_TIMESTAMP();

SELECT EXTRACT(DAY FROM DATE('2018-08-29'));

//mySQL
SELECT ROUND((UNIX_TIMESTAMP(DATE('2018-08-29')) - UNIX_TIMESTAMP(DATE('2018-01-01'))) / (60 * 60 * 24), 0) AS days;

SELECT DATEDIFF(DATE('2018-08-29'), DATE('2018-01-01')) AS days;

//sqlite
SELECT CAST((julianday(CURRENT_TIMESTAMP)) - julianday('2018-01-01')) AS INT) AS days;
```

### Output Redirection

Store query result in another table;

-> Table must not already be defined.

-> Table will have the same # of columns with the same types as the input.

```sql
SELECT DISTINCT cid INTO CourseIds FROM enrolled;

CREATE TABLE CourseIds(
    SELECT DISTINCT cid FROM enrolled
);
```

Insert tuples from query into another table:
-> Inner SELECT must generate the same columns as the target table.

-> DBMSs have different options.syntax on what to do with duplicates.

```sql
INSERT INTO CourseIds(
    SELECT DISTINCT cid FROM enrolled;
)
```

### Output Control

ORDER BY <column\*> [ASC | DESC]

-> Order the output tuples by the values in one or more of their columns.

```sql
SELECT sid, grade FROM enrolled
WHERE cid = '15-721'
ORDER BY grade

SELECT sid, grade FROM enrolled
WHERE cid = '15-721'
ORDER BY grade DESC, sid ASC;
```

LIMIT <count> [offset]

-> Limit the # of tuples returned in output.

-> Can set an offset to return a "range"

```sql
SELECT sid, name FROM student
WHERE login LIKE '%@cs'
LIMIT 20 OFFSET 10
```

### Nested Queries

Queries containing other queries.

They are often difficult to optimize.

Inner queries can appear (almost) anywhere in query.

```sql
SELECT name FROM student WHERE sid IN (SELECT sid FROM enrolled);
```

ALL -> Nust satisfy expression for all rows int sub-query.

ANY-> Nust satisfy expression for at least one row in sub-query

IN -> Equivalent to '=ANY()'.

EXISTS -> At least one row is returned.

```sql
SELECT (SELECT S.name FROM student AS S WHERE S.sid = E.sid) AS sname FROM enrolled as E WHERE cid ='15-445'
```

example: Find student record with the highest id that is enrolled in at least one course.

```sql
SELECT sid, name FROM student
WHERE sid >= ALL(
    SELECT sid FROM enrolled.
)

//or
SELECT sid, name FROM student WHERE sid IN(
    SELECT MAX(sid) FROM enrolled
);
SELECT sid, name FROM student WHERE sid IN(
    SELECT sid FROM enrolled
    ORDER BY sid DESC LIMIT 1
);
```

Find all courses that has no students enrolled in it.

```sql
SELECT * FROM course WHERE NOT EXISTS(
    SELECT * FROM enrolled WHERE course.cid = enrolled.cid
)

```

### Window Functions

Performs a calculation across a set of tuples that related to a single row.

Like an aggregation but tuples are not grouped into a single output tuples.

```sql
SELECT ...FUNC_NAME(...) OVER FROM tableName;
```

Aggregation functions:

-> Anything that we discussed earlier

Special window functions:

-> ROW_NUMBER() -> #of the current row

-> RANK() -> Order position of the current row.

```sql
SELECT *, ROW_NUMBER() OVER() AS row_number FROM enrolled;
```

The OVER keyword specifies how to group together tuples when computing the window function.

Use PARTITION BY to specify group.

```sql
SELECT cid, sid,
	ROW_NUMBER() OVER(PARTITION BY cid)
	FROM enrolled ORDER BY cid;
```

You caan alo include an ORDER BY in the window grouping to sort entries in each group.

```sql
SELECT *,
ROW_NUMBER() OVER (ORDER BY cid)
FROM enrolled ORDER BY cid;
```

Find the student with the highest grade for each course.

```sql
SELECT * FROM(
    SELECT *,
    RANK() OVER(PARTITION BY cid ORDER BY grade ASC)
    AS rank
    FROM enrolled
) AS ranking WHERE ranking.rank = 1
```

## Common Table Expressions

Provides a way to write auxiliary statements for use in a larger query.

-> Things of it like a temp table just for one query.

Alternative to nested queries and views.

```sql
WITH cteName AS(
    SELECT 1
)
SELECT * FROM cteName;
```

You can bind output columns to names before the AS keyword.

```sql
WITH cteName(col1, col2) AS(
    SELECT 1, 2
)
SELECT col1 + col2 FROM ctetName;
```

example: Find student record with the highest id that is enrolled in at least one course.

```sql
WITH cteSource(maxId) as(
    SELECT MAX(sid) FROM enrolled
)

SELECT name FROM student, cteSource WHERE student.sid = cteSource.maxId;
```

Print the sequence of numbers from 1 to 10.

```sql
WITH RECURSIVE cteSource(counter) AS(
    (SELECT 1) UNION ALL
    (SELECT counter + 1 FROM cteSource WHERE counter < 10)
)
SELECT * FROM cteSource;
```

## DCL

### 创建用户

```sql
CREATE USER userName identified by password;
```

```sql
CREATE USER userName;
```

### 用户授权

```sql
GRANT ALL(Alter, Create...., Permission n) on database.table to user [with grant option]
```

all代表授予所有权限， 数据库的表使用\*代表全部，with grant option表示权限可转让。

使用revoke可以进行回收

```sql
revoke all| Permission1, Permission2 on database.table to user
```

### 视图

视图的本质就是一个查询的结果。

```sql
CREATE VIEW viewName as subQueryText[with check option];
```

WITH CHECK OPTION 指当创建后如果要更新视图中的数据，是否要满足子查询中的条件表达式。

删除视图使用`drop`

```sql
DROP VIEW viewName;
```

- 若视图由两个以上基本表导出，则此视图不允许更新。
- 若视图的字段来自字段表达式或常数，则不允许更新。
- 若字段来自集函数，则不允许更新
- 若含有DISTINCT短语则不允许更新
- 若含有嵌套查询并且内层的FROM子句涉及的表也是导出该视图的基本表，则不允许更新。
- 一个不允许更新的视图上定义的视图也不允许更新。

### 索引

```sql
-- 创建索引
CREATE INDEX indexName ON tableName(columnName);
-- 查看表中的索引
SHOW INDEX FROM tableName;
```

删除索引

```sql
DROP INDEX indexName ON tableName(columnName);
```

### 触发器

操作时会生成两个表为new和old.

```sql
CREATE TRIGGER triggerName [BEFORE|AFTER] [INSERT|UPDATE|DELETE] ON tableName|viewName FOR EACH ROW DELETE FROM student WHERE student.sno = new.sno;
```

查看触发器

```sql
SHOW TRIGGER;
```

删除触发器

```sql
DROP TRIGGER triggerName;
```
