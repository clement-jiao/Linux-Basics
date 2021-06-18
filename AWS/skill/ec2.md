## 从ec2实例中获取实例ID
[toc]

[google 相关解答（网页快照）](https://webcache.googleusercontent.com/search?q=cache:a4P8q7qkZDgJ:https://www.itranslater.com/qa/details/2107753663031673856+&cd=9&hl=zh-CN&ct=clnk&gl=sg)

### bash

```bash
# wget
wget -q -O - http://169.254.169.254/latest/meta-data/instance-id

# wget document
wget -q -O - http://169.254.169.254/latest/dynamic/instance-identity/document

# bash script
die() { status=$1; shift; echo "FATAL: $*"; exit $status; }
EC2_INSTANCE_ID="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id || die \"wget instance-id has failed: $?\"`"

# advance
EC2_INSTANCE_ID="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id || die \"wget instance-id has failed: $?\"`"
test -n "$EC2_INSTANCE_ID" || die 'cannot obtain instance-id'

EC2_AVAIL_ZONE="`wget -q -O - http://169.254.169.254/latest/meta-data/placement/availability-zone || die \"wget availability-zone has failed: $?\"`"
test -n "$EC2_AVAIL_ZONE" || die 'cannot obtain availability-zone'
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"


# bash script advance
#!/bin/bash
aws_instance=$(wget -q -O- http://169.254.169.254/latest/meta-data/instance-id)
aws_region=$(wget -q -O- http://169.254.169.254/latest/meta-data/hostname)
aws_region=${aws_region#*.}
aws_region=${aws_region%%.*}
aws_zone=`ec2-describe-instances $aws_instance --region $aws_region`
aws_zone=`expr match "$aws_zone" ".*\($aws_region[a-z]\)"`

```

#### 在Amazon Linux AMI 上
```bash
# sudo apt-get install cloud-utils
$ ec2-metadata -i
instance-id: i-1234567890abcdef0

$ ec2metadata --instance-id

#$ ec2-metadata --help
# bash
EC2_INSTANCE_ID=$(ec2metadata --instance-id)
```



### python

```python
import boto.utils
region=boto.utils.get_instance_metadata()['local-hostname'].split('.')[1]


# 单行
python -c "import boto.utils; print boto.utils.get_instance_metadata()['local-hostname'].split('.')[1]"

# public_hostname
boto.utils.get_instance_metadata()['placement']['availability-zone'][:-1]

```



### GO

```go
import (
    "github.com/mitchellh/goamz/aws"
    "log"
)

func getId() (id string) {
    idBytes, err := aws.GetMetaData("instance-id")
    if err != nil {
        log.Fatalf("Error getting instance-id: %v.", err)
    }

    id = string(idBytes)

    return id
}
```



### system file

只需检查  `var/lib/cloud/instance `  **符号链接**，它应指向 `/var/lib/cloud/instances/{instance-id}`，
其中  `{instance_id}`  是您的实例ID

### 参考文档

[http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html]



## Install-docker

UPDATE (March 2020, thanks @ic): I don't know the exact AMI version but `yum install docker` now works on the latest Amazon Linux 2. The instructions below may still be relevant depending on the vintage AMI you are using.

Amazon changed the install in Linux 2. One no-longer using 'yum' See: https://aws.amazon.com/amazon-linux-2/release-notes/

```bash
sudo amazon-linux-extras install docker
sudo systemctl docker start
sudo usermod -a -G docker ec2-user
```



















