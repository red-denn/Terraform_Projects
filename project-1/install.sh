#!/bin/bash
sudo su
yum update -y
yum install -y httpd
cd /var/www/html
#wget https://github.com/azeezsalu/techmax/archive/refs/heads/main.zip
#unzip main.zip
#cp -r techmax-main/* /var/www/html/
#rm -rf techmax-main main.zip
sudo aws s3 sync s3://ambulah/techmax-main /var/www/html
systemctl enable httpd 
systemctl start httpd