# container_advisor

monitor docker container's mem + cpu + io, post data to aws cloudwatch


# How to use

## pre-install:
```shell
sudo apt-get install awscli -y
aws configure # input your access_key and secret_key
```

## download script
```shell
curl https://raw.githubusercontent.com/westmisfit/container_advisor/master/docker_cloudwatch.sh | sudo tee /usr/local/bin/docker_cloudwatch.sh
sudo chmod +x /usr/local/bin/docker_cloudwatch.sh
```

## execute script every 1 minute
```shell
echo "*/1 * * * * ubuntu /usr/local/bin/docker_cloudwatch.sh >/home/ubuntu/docker_cloudwatch.log 2>&1" | sudo tee /etc/cron.d/docker_cloudwatch
```
