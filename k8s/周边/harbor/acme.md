### acme.sh 示例
```bash
#!/bin/bash
# Usage: ./cert.sh [init|refresh]

# echo "15 16 * * * /var/docker-environment/base/cert.sh refresh" >> /var/spool/cron/root

name=$1
# SHELL_FOLDER=$(cd "$(dirname "$0")";pwd)
SHELL_FOLDER=/data/secret/cert/
domainName=registry-harbor.clemente.net
if [ -z $name ]; then
  name=""
fi

cd $SHELL_FOLDER

if [ $name == "init" ]; then
  echo "init acmesh.sh"
  curl  https://get.acme.sh | sh
  chmod a+x ~/.acme.sh/acme.sh
  # auto update
  ~/.acme.sh/acme.sh  --upgrade
  ~/.acme.sh/acme.sh  --issue -d $domainName --standalone --httpport 80 --force
  elif [ $name == "refresh" ]; then
      echo "refresh domain cert"
      # rm -rf  /data/secret/cert/server.key
      # auth file to nginx-html
      /usr/bin/docker stop nginx
      ~/.acme.sh/acme.sh  --installcert --issue -d $domainName \
                          --key-file $SHELL_FOLDER/server.key \
                          --fullchain-file $SHELL_FOLDER/server.crt \
                          --standalone 
                          # --force
                          # --reloadcmd "/usr/bin/docker start nginx"
      chown -R 10000:10000 /data/secret/cert/
      /usr/bin/docker start nginx
  else
    echo "Doesn't support arg $name, please use ./cert.sh [init|refresh]"
fi
```