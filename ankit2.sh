#!/bin/bash
#aws configure
#read -p 'enter the ipv4 address for vpc' IP
#aws ec2 create-vpc  --cidr-block $IP
#read -p 'enter the vpc id' vpc_id
#read -p 'enter the vpc name'  vpc_name
#aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=$vpc_name
#read -p 'enter the public subnet ip' pub_sub_ip
#aws ec2 create-subnet --vpc-id  $vpc_id --availability-zone ap-south-1a --cidr-block $pub_sub_ip
#read -p 'enter the public_subnet_id' pub_sub_id
#read -p 'enter the public subnet name' pub_sub_name
#aws ec2 create-tags --resources $pub_sub_id  --tags Key=Name,Value=$pub_sub_name
#FOR PRIVATE SUBNET
#read -p 'enter the private subnet ip'  priv_sub_ip
#aws ec2 create-subnet --vpc-id  $vpc_id --availability-zone ap-south-1a --cidr-block $priv_sub_ip
#read -p 'enter the private subnet id' priv_sub_id
#read -p 'enter the private subnet name' priv_sub_name
#aws ec2 create-tags --resources $priv_sub_id  --tags Key=Name,Value=$priv_sub_name
#FOR CREATING INTERNET GATEWAY
#aws ec2 create-internet-gateway
#read -p 'enter internet gateway id' igw
#aws ec2 attach-internet-gateway --internet-gateway-id $igw --vpc-id  $vpc_id
#read -p 'enter the name of internet gateway' name
#aws ec2 create-tags --resources $igw  --tags Key=Name,Value=$name

#EDIT ROUTE TABLE-
#read -p 'enter the vpc route table id' vpc_rtb
#aws ec2 create-route --route-table-id $vpc_rtb --destination-cidr-block 0.0.0.0/0 --gateway-id $igw

#CREATE SECURITY GROUP-
#read -p 'enter the NAT security group name' NAT_SG_NAME
#aws ec2 create-security-group --group-name $NAT_SG_NAME --description "My CLI security group" --vpc-id  $vpc_id
#read -p 'enter the NAT sg id' NAT_SG_ID
#read -p 'enter the NAT sg name' NAT_sg_name
#aws ec2 create-tags    --resources $NAT_SG_ID --tags Key=Name,Value=$NAT_sg_name

#for creating pivate security group-
#read -p 'enter the private security group name' priv_SG
#aws ec2 create-security-group --group-name $priv_SG --description "My CLI security group" --vpc-id  $vpc_id
#read -p 'enter the private sg id' priv_SG_ID
#read -p 'enter the private sg name' priv_sg_name
#aws ec2 create-tags    --resources $priv_SG_ID --tags Key=Name,Value=$priv_sg_name

#FOR CREATING THE PUBLIC SECURITY GROUP-
#read -p 'enter the public security group name' pub_SG
#aws ec2 create-security-group --group-name $pub_SG --description "My CLI security group" --vpc-id  $vpc_id
#read -p 'enter the public sg id' PUB_SG_ID
#read -p 'enter the public sg name' pub_sg_name
#aws ec2 create-tags    --resources $PUB_SG_ID --tags Key=Name,Value=$pub_sg_name


#CREATE ROUTE TABLE -
#aws ec2 create-route-table --vpc-id   $vpc_id
#read -p 'enter the route table id' RT_ID
#read -p 'enter the route table name' RT_NAME
#aws ec2 create-tags    --resources $RT_ID --tags Key=Name,Value=$RT_NAME

#FOR SUBNET ASSOCIATION-
#aws ec2 associate-route-table --route-table-id $RT_ID --subnet-id $priv_sub_id

#EDIT SECURITY GROUP FOR NAT_SG

#aws ec2 authorize-security-group-ingress --group-id $NAT_SG_ID --protocol tcp  --port 22 --cidr 0.0.0.0/0
#aws ec2 authorize-security-group-ingress --group-id $NAT_SG_ID --protocol tcp  --port 80 --cidr $priv_sub_ip
#aws ec2 authorize-security-group-ingress --group-id $NAT_SG_ID --protocol tcp  --port 443 --cidr $priv_sub_ip
#aws ec2 authorize-security-group-ingress --group-id $NAT_SG_ID --protocol icmp  --port all --cidr $priv_sub_ip
#aws ec2 authorize-security-group-ingress --group-id $NAT_SG_ID --protocol all  --port all --source-group $priv_SG_ID

#EDIT SECURITY GROUP FOR PUBLIC_SG

#aws ec2 authorize-security-group-ingress --group-id $PUB_SG_ID --protocol tcp  --port 22 --cidr 13.233.177.0/29
#aws ec2 authorize-security-group-ingress --group-id $PUB_SG_ID --protocol tcp  --port 80 --cidr 0.0.0.0/0
#aws ec2 authorize-security-group-ingress --group-id $PUB_SG_ID --protocol tcp  --port 443 --cidr 0.0.0.0/0
#aws ec2 authorize-security-group-ingress --group-id $PUB_SG_ID --protocol tcp  --port 22  --cidr 0.0.0.0/0
#aws ec2 authorize-security-group-ingress --group-id $PUB_SG_ID --protocol all  --port all --source-group $NAT_SG_ID


#EDIT SECURITY GROUP FOR PRIVATE_SG

#aws ec2 authorize-security-group-ingress --group-id $priv_SG_ID --protocol tcp  --port 22 --cidr  $pub_sub_ip
#aws ec2 authorize-security-group-ingress --group-id $priv_SG_ID --protocol tcp  --port 8080 --source-group $PUB_SG_ID
#aws ec2 authorize-security-group-ingress --group-id $priv_SG_ID --protocol all  --port all --source-group $NAT_SG_ID


#FOR CREATING KEY PAIR-
#read -p 'enter the key name' name
#aws ec2 create-key-pair --key-name $name --query 'KeyMaterial' --output text > $name
#sudo chmod 600 $name
#aws ec2 run-instances --image-id  ami-00999044593c895de --count 1 --instance-type t2.micro --key-name $name --placement AvailabilityZone=ap-south-1a --security-group-ids $NAT_SG_ID --subnet-id $pub_sub_id  --associate-public-ip-address
#read -p 'enter the nat instance name' nat_ins_name
#read -p 'enter the nat instance id' nat_ins_id
#aws ec2 create-tags --resources $nat_ins_id  --tags Key=Name,Value=$nat_ins_name
#aws ec2 run-instances --image-id  ami-04b1ddd35fd71475a --count 1 --instance-type t2.micro --key-name $name --placement AvailabilityZone=ap-south-1a --security-group-ids $PUB_SG_ID --subnet-id $pub_sub_id  --associate-public-ip-address
#read -p 'enter the pub instance name' pub_ins_name
#read -p 'enter the pub instance id' pub_ins_id
#aws ec2 create-tags --resources $pub_ins_id  --tags Key=Name,Value=$pub_ins_name

#aws ec2 run-instances --image-id  ami-04b1ddd35fd71475a --count 1 --instance-type t2.micro --key-name $name --placement AvailabilityZone=ap-south-1a --security-group-ids $priv_SG_ID --subnet-id $priv_sub_id
#read -p 'enter the private instance name' priv_ins_name
#read -p 'enter the private instance id' priv_ins_id
#aws ec2 create-tags --resources $priv_ins_id  --tags Key=Name,Value=$priv_ins_name

#EDIT ROUTE  FOR PRIVATE-
#read -p 'enter the private route table id' PRI_RT
#read -p 'enter the nat instance id' ins_id
#aws ec2 create-route --route-table-id $PRI_RT --destination-cidr-block 0.0.0.0/0 --instance-id $ins_id
read -p 'enter the PR_PUB_INS public ip for ssh' PUB_IP
read -p 'enter the PR_PRIV_INS PRIVATE IP FOR SSH' private_ip
sudo chmod 600 ABCD
sudo scp -i ABCD /home/ec2-user/ABCD ec2-user@$PUB_IP:/home/ec2-user/

#for itegration of apache tomcat
ssh -i ABCD ec2-user@$PUB_IP sudo yum install httpd
read -p 'enter the key name' key
ssh -i ABCD ec2-user@$PUB_IP   sudo openssl genrsa -des3 -out $key.key 1024
ssh -i ABCD ec2-user@$PUB_IP   sudo openssl req -new -key $key.key -out $key.csr
ssh -i ABCD ec2-user@$PUB_IP   sudo cp $key.key $key.key.org
ssh -i ABCD ec2-user@$PUB_IP   sudo openssl rsa -in $key.key.org -out $key.key
ssh -i ABCD ec2-user@$PUB_IP   sudo openssl x509 -req -days 365 -in $key.csr -signkey $key.key -out $key.crt
ssh -i ABCD ec2-user@$PUB_IP   sudo mv $key.* /etc/pki/tls/certs/
ssh -i ABCD ec2-user@ sudo yum install -y mod_ssl
read -p 'Enter configuration file name' exam
read -p 'Enter server name' ser
read -p 'Enter serverAlias Name' serAli
ssh -i ABCD ec2-user@$PUB_IP   sudo touch $exam
ssh -i ABCD ec2-user@$PUB_IP   sudo chmod 666 $exam
ssh -i ABCD ec2-user@$PUB_IP   "echo '<VirtualHost *:443>'>> $exam"
ssh -i ABCD ec2-user@$PUB_IP   "echo '          ServerAdmin webmaster@localhost'>>$exam"
ssh -i ABCD ec2-user@$PUB_IP   "echo '          serverName' $ser>>$exam"
ssh -i ABCD ec2-user@$PUB_IP   "echo '          ServerAlias' $serAli>>$exam"
ssh -i ABCD ec2-user@$PUB_IP   "echo '          DocumentRoot /var/www/html/'>>$exam"
ssh -i ABCD ec2-user@$PUB_IP   "echo '          SSLProxyEngine on'>>$exam"
ssh -i ABCD ec2-user@$PUB_IP   "echo '          ProxyPass / http://"$private_ip":8080/'>>$exam"
ssh -i ABCD ec2-user@$PUB_IP   "echo '          ProxyPassReverse / http://"$private_ip":8080/'>>$exam"
ssh -i ABCD ec2-user@$PUB_IP   "echo '          '>>$exam"
ssh -i ABCD ec2-user@$PUB_IP   "echo '          SSLEngine on'>>$exam"
ssh -i ABCD ec2-user@$PUB_IP   "echo '          SSLCertificateFile /etc/pki/tls/certs/'$key'.crt'>>$exam"
ssh -i ABCD ec2-user@$PUB_IP   "echo '          SSLCertificateKeyFile /etc/pki/tls/certs/'$key'.key'>>$exam" 
ssh -i ABCD ec2-user@$PUB_IP   "echo '</VirtualHost>'>>$exam"
ssh -i ABCD ec2-user@$PUB_IP   sudo chmod 666 /etc/httpd/conf.d/$exam.conf
ssh -i ABCD ec2-user@$PUB_IP   sudo mv $exam /etc/httpd/conf.d/$exam.conf
sudo ssh -i ABCD ec2-user@$PUB_IP   sudo chmod 666 /etc/hosts
sudo ssh -i ABCD ec2-user@$PUB_IP   echo  $PUB_IP   $ser>>/etc/hosts
sudo ssh -i ABCD ec2-user@$PUB_IP   sudo chmod 644 /etc/hosts
sudo ssh -i ABCD ec2-user@$PUB_IP   sudo systemctl restart httpd
sudo ssh -i ABCD ec2-user@$PUB_IP   sudo ssh -i ABCD ec2-user@$private_ip sudo yum install java
sudo ssh -i ABCD ec2-user@$PUB_IP   sudo ssh -i ABCD ec2-user@$private_ip sudo wget https://mirrors.estointernet.in/apache/tomcat/tomcat-8/$
sudo ssh -i ABCD ec2-user@$PUB_IP   sudo ssh -i ABCD ec2-user@$private_ip sudo tar -xzvf /home/ec2-user/apache-tomcat-8.5.61.tar.gz 

#sudo ssh -i ABCD ec2-user@$pub_ip sudo ssh -i ABCD ec2-user@$private_ip sudo chmod 755 /apache-tomcat-8.5.61/webapps/
#sudo ssh -i ABCD ec2-user@$pub_ip sudo ssh -i ABCD ec2-user@$private_ip  mv /home/ec2-user/jenkins.war /home/ec2-user/apache-tomcat-8.5.6$

sudo ssh -i PR1 ec2-user@$public_ip sudo ssh -i /home/ec2-user/example ec2-user@$private_ip sudo chmod 755 /apache-tomcat-8.5.61/bin/
