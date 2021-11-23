rh294虚拟机

```
username: kiosk
password: redhat

username: root
password: Asimov
```

apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget libbz2-dev  libbz2-dev libncurses5-dev libgdbm-dev liblzma-dev sqlite3 libsqlite3-dev openssl libssl-dev tcl8.6-dev tk8.6-dev libreadline-dev zlib1g-dev



export LDFLAGS="-L /usr/local/package/libssl/lib"

export CPPFLAGS="-I /usr/local/package/libssl/include"

export PKG_CONFIG_PATH="/usr/local/package/libssl/lib/pkgconfig"

