FROM redis:5.0.10-alpine

RUN mkdir -p /etc/redis /usr/local/redis /data/redis-5.0.10

COPY entrypoint.sh redis.conf /usr/local/redis/

RUN chmod +x /usr/local/redis/entrypoint.sh
RUN chown -R redis:redis /etc/redis /usr/local/redis

ENTRYPOINT /usr/local/redis/entrypoint.sh
