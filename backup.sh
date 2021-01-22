#!/bin/bash
date=`TZ=IST-5:30 date +%F_%T`
zip -r /home/ec2-user/backup_$date /etc/httpd/
aws s3 mv /home/ec2-user/backup_*.zip s3://harishs3class
