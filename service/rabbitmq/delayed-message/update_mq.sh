#!/bin/bash
### https://blog.dockbit.com/templating-your-dockerfile-like-a-boss-2a84a67d28e9
### https://github.com/davyin-co/docker-elasticsearch-ik/tree/master （对此表示感谢）

version=3.11.18
render() {
  sedStr="s/mq_version/$version/g"
  sed -e "$sedStr" $1
}
render Dockerfile.template > Dockerfile
wget https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/3.11.1/rabbitmq_delayed_message_exchange-3.11.1.ez
docker build -t rabbitmq-dm:$version-management .
