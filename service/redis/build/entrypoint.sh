# 判断文件存在且有效(未完成)

if [ ! -s /etc/redis/redis.conf ]; then
    /bin/cp -p /usr/local/redis/redis.conf /etc/redis/redis.conf && \
    /bin/chown -R redis:redis /etc/redis
fi
if [ $0 == 0 ]; then
    echo "copy config file sucessfull !"
fi

redis-server /etc/redis/redis.conf