@[TOC](Servlet)

# Servlets

Servlet有4个Java包

* javax.servlet 包含定义Servlet和Servlet容器之间契约的类和接口
* javax.servlet.http 定义Http Servlet和Servlet容器之契约的类和接口
* javax.servlet.annotation， 包含标注Servlet，Filter， Listener的标注。还为被标注元件定义元数据。
* javax.servlet,descriptor 包含提供程序化登录web应用程序的配置信息的类型

Servlet接口定义的契约为Servlet容器将Servlet类载入内存，并在Servlet实例上调用具体的方法。

用户请求导致Servlet容器调用Servlet的service方法， 并传入ServletRequest和ServletResponse两个实例。

## Servlet

Servlet接口定义了5个方法

```java
void init(ServletConfig config) throws ServletException;
void service(ServletRequest request, ServletResponse response) throws IOException, ServletException;
void destory();
String getServletInfo();
ServletConfig getServletConfig();
```

init , service, destory是三个生命周期方法

* init： 当Servlet被第一次请求时调用
* service： 每当请求Servlet时调用
* destory: 销毁Servlet时调用



## 基础的Servlet程序

```java
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebServlet;
import java.io.IOException;

@WebServlet(name = "MyServlet",urlPatterns = {"/my"})
public class MyServlet implements javax.servlet.Servlet{
    private transient ServletConfig servletConfig;

    @Override
    public void init(ServletConfig servletConfig) throws ServletException {
        this.servletConfig = servletConfig;
    }

    @Override
    public ServletConfig getServletConfig() {
        return servletConfig;
    }

    @Override
    public String getServletInfo() {
        return "My Servlet";
    }

    @Override
    public void service(ServletRequest servletRequest, ServletResponse servletResponse) throws ServletException, IOException {
        var servletName = servletConfig.getServletName();
        servletResponse.setContentType("text/html");
        try(var out = servletResponse.getWriter()){
            out.println("""
                    <html>
                    <head></head>
                    <body>Hello from """ + servletName + "</body></html>");
        }
    }

    @Override
    public void destroy() {
        
    }
}

```

WebServlet注解声明一个Servlet

## ServletRequest

ServletRequest 接口中有一些方法

```java
public int getContentLength();	//获取请求主体的字节数
public java.lang.String getContentType();	//返回请求主题的MIME类型，若未知则返回null
public java.lang.String getParameter(java.lang.String name);	//返回请求指定参数的值
public java.lang.String getProtocol();		//获取HTTP请求的协议的名称和版本
```



当用如下URI调用

```
http://domain/context/servletName?id=123
```

使用如下代码获取id

```java
var id = request.getParameter("id");
```

getParameterNames, getParameterMap, getParameterValues获取表单域名，值以及查询字符串。



## ServletResponse

ServletResponse接口表示一个Servlet响应。


getWriter方法返回的PrintWriter对象默认使用Latin-1编码



## ServletConfig

当Servlet容器初始化Servlet时，Servlet容器会给Servlet的init方法传入一个ServletConfig实例。

ServletConfig封装通过@WebServlet或部署描述符传给Servlet的配置信息。这样传入的每一个信息就叫一个初始参数。

为了从Servlet内部获取初始参数的值， 要在Servlet的init方法的ServletConfig中调用getInitParameter方法。



```java
java.lang.String getInitParameter(java.lang.String name);

```

getInitParameterNames方法返回一个Enumeration

```java
java.util.Enumeration<java.lang.String> getInitParameterNames();
```

```java
import javax.servlet.*;
import javax.servlet.annotation.WebInitParam;
import javax.servlet.annotation.WebServlet;
import java.io.IOException;

@WebServlet(name = "ServletConfigDemoServlet",
urlPatterns = {"/servletConfigDemo"},
initParams = {
        @WebInitParam(name = "admin", value = "Harry Taciak"),
        @WebInitParam(name = "email", value = "admin@example.com")
})
public class ServletConfigDemoServlet implements Servlet {
    private transient ServletConfig servletConfig;

    @Override
    public ServletConfig getServletConfig() {
        return servletConfig;
    }

    @Override
    public void init(ServletConfig servletConfig) throws ServletException {
        this.servletConfig = servletConfig;
    }

    @Override
    public void service(ServletRequest servletRequest, ServletResponse servletResponse) throws ServletException, IOException {
        var servletConfig = getServletConfig();
        var admin = servletConfig.getInitParameter("admin");
        var email = servletConfig.getInitParameter("email");
        servletResponse.setContentType("text/html");
        try(var out = servletResponse.getWriter()){
            out.println("""
                    <html>
                    <head></head>
                    <body>
                        Admin: """ + admin +
                    "<br/>Email: " + email +
                    """
                    </body>
                    </html>
                    """);
        }
    }

    @Override
    public String getServletInfo() {
        return "ServletConfig demo";
    }

    @Override
    public void destroy() {

    }
}

```

