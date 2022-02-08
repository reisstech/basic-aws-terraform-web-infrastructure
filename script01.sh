#!/bin/bash

sudo yum update -y
sudo yum install httpd -y
cd /var/www/html
sudo echo "<h1>Webserver01 OK!</h1>" > index.html
sudo service httpd start
