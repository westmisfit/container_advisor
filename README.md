# container_advisor

monitor docker container's mem + cpu + io, post data to aws cloudwatch


# How to use

## Install wget

### For ubuntu

```shell
sudo apt-get install wget -y
```

### For amazon-linux

```shell
sudo yum install wget -y
```

## Install awscli

### For ubuntu

```shell
sudo apt-get install awscli -y
aws configure # input your access_key and secret_key
```

### For amazon-linux

```shell
curl -O https://bootstrap.pypa.io/get-pip.py
sudo python27 get-pip.py
sudo ln -s /usr/local/bin/pip /usr/bin/pip
rm get-pip.py

sudo pip install awscli
sudo ln -s /usr/local/bin/aws /usr/bin/aws

aws configure # input your access_key and secret_key
```


## Download collect data script
```shell
curl https://raw.githubusercontent.com/westmisfit/container_advisor/master/docker_cloudwatch.sh | sudo tee /usr/local/bin/docker_cloudwatch.sh
sudo chmod +x /usr/local/bin/docker_cloudwatch.sh
```

## Add corn task, collect data every 1 minute
```shell
echo "*/1 * * * * $USER /usr/local/bin/docker_cloudwatch.sh >$HOME/docker_cloudwatch.log 2>&1" | sudo tee /etc/cron.d/docker_cloudwatch
```
