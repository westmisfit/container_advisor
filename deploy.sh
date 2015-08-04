# pre-install:
sudo apt-get install awscli -y
aws configure # input your access_key and secret_key

# download script
curl https://gist.githubusercontent.com/forhot2000/d007590b2e5a8bfafac7/raw/ae14f7dea863c09e96affb6e9aaaa76537d65f15/docker_cloudwatch.sh | sudo tee /usr/local/bin/docker_cloudwatch.sh
sudo chmod +x /usr/local/bin/docker_cloudwatch.sh
# execute script every 1 minute
echo "*/1 * * * * ubuntu /usr/local/bin/docker_cloudwatch.sh >/home/ubuntu/docker_cloudwatch.log 2>&1" | sudo tee /etc/cron.d/docker_cloudwatch
