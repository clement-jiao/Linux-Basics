###  Nginx中accept锁的机制与实现
nginx 采用多进程的模型, 当一个请求过来的时候, 系统会对进程进行加锁操作, 保证只有一个进程来接受请求。
