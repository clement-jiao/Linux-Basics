#!/bin/bash
### https://blog.dockbit.com/templating-your-dockerfile-like-a-boss-2a84a67d28e9
### https://github.com/davyin-co/docker-elasticsearch-ik/tree/master （对此表示感谢）
render() {
sedStr="
  s/%%VERSION%%/$version/g;
"

sed -e "$sedStr" $1
}

versions=(7.10.1 7.11.2 7.12.1 7.13.4 7.14.2 7.16.3 7.17.6 8.1.3 8.2.3 8.3.3 8.4.3)
for version in ${versions[*]}; do
  if [ ! -d $version ]; then
    mkdir $version
  fi
  render Dockerfile.template > $version/Dockerfile
done
