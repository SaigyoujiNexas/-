# IO多路复用

通过DMA可以实现单线程进行多路IO

```c
while(1) {
    for(fdx in fda to fde){
        if (fdx.havedata){
            processData(fdx);
        }
    }
}
```

而在Linux系统中， select， poll， epoll则也可以实现单线程多路IO

## select

select系统调用的的用途是：在一段指定的时间内，监听用户感兴趣的文件描述符上可读、可写和异常等事件

![image-20231116172133375](https://s2.loli.net/2023/11/16/CmJ93GIe2giQ4ar.png)

用户可以注册多个socket，然后不断地调用select读取被激活的socket，即可达到在同一个线程内同时处理多个IO请求的目的。而在同步阻塞模型中，必须通过多线程的方式才能达到这个目的。

### api

```c
#include <sys/select.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
int select(int maxfdp, fd_set *readset, fd_set *writeset, fd_set *exceptset,struct timeval *timeout);
```

maxfdp：被监听的文件描述符的总数，它比所有文件描述符集合中的文件描述符的最大值大1，因为文件描述符是从0开始计数的；

readfds、writefds、exceptset：分别指向可读、可写和异常等事件对应的描述符集合。

timeout:用于设置select函数的超时时间，即告诉内核select等待多长时间之后就放弃等待。timeout == NULL 表示等待无限长的时间

timeval结构体定义如下：

```c
struct timeval
{      
    long tv_sec;   /*秒 */
    long tv_usec;  /*微秒 */   
};
```

```c
#include <sys/select.h>   
int FD_ZERO(int fd, fd_set *fdset);   //一个 fd_set类型变量的所有位都设为 0
int FD_CLR(int fd, fd_set *fdset);  //清除某个位时可以使用
int FD_SET(int fd, fd_set *fd_set);   //设置变量的某个位置位
int FD_ISSET(int fd, fd_set *fdset); //测试某个位是否被置位
```

示例如下：

```c
sockfd = socket(AF_INET, SOCK_STREAM, 0);
memset(&addr, 0, sizeof(addr));
addr.sin_family = AF_INET;
addr.sin_port = htons(2000);
addr.sin_addr.s_addr = INADDR_ANY;
bind(sockfd, (struct sockaddr*)&addr, sizeof(addr));
listen(sockfd, 5);

for(int i = 0; i < 5; i++){
    memset(&client, 0, sizeof(client));
    addrlen = sizeof(client);
    fds[i] = accept(sockfd, (struct sockaddr*)&client, &addrlen);
    if(fds[i] > max)
        max = fds[i];
}
while(1) {
    FD_ZERO(&rset);
    for(int i = 0; i < 5; i++){
        FD_SET(fds[i], &rset);
    }
    puts("round again");
    select(max + 1, &rset, NULL, NULL, NULL);
    for(int i = 0; i < 5; i++){
        if(FD_ISSET(fds[i], &rset)){
            memset(buffer, 0, MAXBUF);
            read(fds[i], buffer, MAXBUF);
            puts(buffer);
        }
    }
}
```

select本质上是通过设置或者检查存放fd标志位的数据结构来进行下一步处理。这样所带来的缺点是：

1、单个进程可监视的fd数量被限制，即能监听端口的大小有限。一般来说这个数目和系统内存关系很大，具体数目可以cat/proc/sys/fs/file-max察看。32位机默认是1024个。64位机默认是2048.

2、 对socket进行扫描时是线性扫描，即采用轮询的方法，效率较低：当套接字比较多的时候，每次select()都要通过遍历FD_SETSIZE个Socket来完成调度,不管哪个Socket是活跃的,都遍历一遍。这会浪费很多CPU时间。如果能给套接字注册某个回调函数，当他们活跃时，自动完成相关操作，那就避免了轮询，这正是epoll与kqueue做的。

3、需要维护一个用来存放大量fd的数据结构，这样会使得用户空间和内核空间在传递该结构时复制开销大。

## poll

```c
for (int i = 0; i < 5; i++){
    memset(&client,  0, sizeof(client));
    addrlen = siseof(client);
    poolfds[i].fd = accept(sockfd, (struct sockaddr*)&client, &addrlen);
    pollfds[i].event = POLLIN;
}
sleep(1);
while(1){
    puts("round again");
    poll(pollfdsm 5, 50000);
    for(int i = 0; i < 5; i++){
        if(pollfds[i].revents & POLLIN){
            pollfds[i].revents = 0;
            memset(buffer, 0, MAXBUF);
            read(pollfds[i].fd, buffer, MAXBUF);
            puts(buffer);
        }
    }
}
```

