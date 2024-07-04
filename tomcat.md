# 1.1 Web应用程序

一个web应用由多部分组成（静态web， 动态web）

* html, css, js
* jsp, servlet
* java 程序
* jar包
* 配置文件

# 1.2 静态web

若服务器上一直存在这些文件， 则直接进行读取， 通信。

* 静态web存在的缺点
  * Web页面无法动态更新
  * 轮播图，点击特效： 伪动态
  * 无法和数据库交互

# 1.3 动态Web

缺点：

* 加入服务器的资源出现错误后，需要重写后台程序

优点：

* 页面可以动态更新
* 可以与数据库交互

# 2  web服务器

ASP, JSP, PHP

* ASP: 微软, 国内最早流行的， 在HTML中嵌入VBS， ASP + COM;

* JSP:本质是Servlet, 可以承载三高问题。
* PHP： 开发速度快， 功能强大，跨平台，代码简单， 但是无法承载高并发的情况。 

 

IIS：ASP..., Windows 中自带的。

## 启动Tomcat

startup, shutdown命令;

mysql 默认端口： 3306

http默认端口： 80

https默认端口：443

Tomcat默认端口: 8080

访问网页的方法：

1. 输入域名
2. 在hosts和DNS中查找IP地址

# 3.Http

## What is http

HTTP（超文本传输协议 Hyper Text Transition Protocol）是一个简单的请求-响应协议， 通常运行在TCP上。

## 两个时代

* http 1.0
  * HTTP/1.0： 客户端与服务器连接后， 只能获得一个web资源，断开连接
* http 2.0
  * HTTP/1.1:  客户端与服务器连接后， 可以获得多个web资源

## Http请求

* 客户端--发请求( Request )--服务器

Request URL

Request Method

Status Code

Remote Address

Referrer Policy



### 1. 请求行

请求方式： Get, Post, HEAD，DELETE，PUT, TRACT...

* Get: 请求能够携带的参数很少，大小有限制，会在URL显示数据内容，不安全但高效
* Post: 请求能够携带的参数无限制， 不会在URL显示数据内容， 安全但不高效

### 2.消息头

```
Accept:text/html //告诉浏览器所支持的数据类型
Accept-Encoding: gzip, deflate, br	//支持哪种编码格式
Accept-Language: zh-CN, zh; q=0.9	//语言环境
Cache-Control:max-age=0	//缓存控制
Connection: keep-alive	//请求完成是断开还是保持连接
HOST: //主机....
```



## Http响应



服务器--响应--客户端

```
Cache-Control:private --- 缓存控制

Connection:Keep-Alive --- 连接

Content-Encoding: gzip ---编码
Content-Type:text/html ---类型
```

### 1.响应体

```
Accept:text/html //告诉浏览器所支持的数据类型
Accept-Encoding: gzip, deflate, br	//支持哪种编码格式
Accept-Language: zh-CN, zh; q=0.9	//语言环境
Cache-Control:max-age=0	//缓存控制
Connection: keep-alive	//请求完成是断开还是保持连接
HOST: //主机....
Refresh: 告诉客户端多久刷新一次
Location: 让网页重新定位
```

### 2. 响应状态码

200: 请求响应成功

4xx： 找不到资源

* 资源不存在

3xx: 请求重定向

5xx: 服务器代码错误

* 502 网关错误、

# 4. Maven

在JavaWeb开发中，需要大量jar包

## 4.1 Maven项目架构管理工具

用来方便导入jar包

Maven的核心思想： 约定大于配置

* 有约束， 不要去违反

Maven会规定如何去编写Java代码，
