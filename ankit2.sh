#!/bin/bash
aws configure

date=`TZ=IST-5:30 date +%F_%T`
echo "ENTER THE DETAIL"
read -p 'enter the ipv4 address for vpc' IP  
read -p 'enter the prifix name' prifix
read -p 'enter the public subnet ip' pub_sub_ip
read -p 'enter the private subnet ip'  priv_sub_ip

vpcid=`aws ec2 create-vpc --cidr-block $IP --query Vpc.VpcId --output text` 
aws ec2 create-tags --resources $vpcid --tags Key=Name,Value=$prifix-vpc 
echo "VPC created with VPC ID :" $vpcid | tee -a harish_ver3_$date.txt

#FOR CREATING PUBLIC SUBNET

publicid=`aws ec2 create-subnet --vpc-id $vpcid --cidr-block $pub_sub_ip --availability-zone ap-south-1a --query Subnet.SubnetId --output text` 
aws ec2 create-tags --resources $publicid --tags Key=Name,Value=$prifix-pub-sub 
echo "Publicsubnet created with subnet id :" $publicid | tee -a harish_ver3_$date.txt

#FOR PRIVATE SUBNET

privateid=`aws ec2 create-subnet --vpc-id $vpcid --cidr-block $priv_sub_ip --availability-zone ap-south-1a --query Subnet.SubnetId --output text` 
aws ec2 create-tags --resources $privateid  --tags Key=Name,Value=$prifix-priv-sub 
echo "Private subnet created with sunnet id :" $privateid | tee -a harish_ver3_$date.txt

#FOR CREATING INTERNET GATEWAY
igw=`aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text` 
aws ec2 attach-internet-gateway --internet-gateway-id $igw --vpc-id  $vpcid
aws ec2 create-tags --resources $igw  --tags Key=Name,Value=$prifix-igw
echo "Internet gateway created with igw id :" $igw | tee -a harish_ver3_$date.txt

#EDIT ROUTE TABLE-
vpcrtb=`aws ec2 create-route-table --vpc-id $vpcid --query RouteTable.RouteTableId --output text`
echo $vpcrtb
aws ec2 create-route --route-table-id $vpcrtb --destination-cidr-block 0.0.0.0/0 --gateway-id $igw
aws ec2 associate-route-table --route-table-id $vpcrtb --subnet-id $publicid

#CREATE SECURITY GROUP-
nat=`aws ec2 create-security-group --group-name $prifix-nat-sg --description "My nat security group" --vpc-id  $vpcid --query GroupId --output text`
echo "natsg created with natsg id :" $nat | tee -a harish_ver3_$date.txt

#for creating pivate security group-
priv=`aws ec2 create-security-group --group-name $prifix-priv-sg --description "My CLI security group" --vpc-id  $vpcid --query GroupId --output text`
echo "Private Securitygroup Created with sgid :" $priv | tee -a harish_ver3_$date.txt

#FOR CREATING THE PUBLIC SECURITY GROUP-
pub=`aws ec2 create-security-group --group-name $prifix-pub_sg --description "My CLI security group" --vpc-id  $vpcid --query GroupId --output text`
echo "Public Security group created with public sg id :" $pub  | tee -a harish_ver3_$date.txt

#CREATE ROUTE TABLE -
RT=`aws ec2 create-route-table --vpc-id $vpcid  --query RouteTable.RouteTableId --output text`
echo $RT
aws ec2 create-tags    --resources $RT --tags Key=Name,Value=$prifix-rt
echo "route table created with routetable id :" $RT  | tee -a harish_ver3_$date.txt

#FOR SUBNET ASSOCIATION-
aws ec2 associate-route-table --route-table-id $RT --subnet-id $privateid

#EDIT SECURITY GROUP FOR NAT_SG
aws ec2 authorize-security-group-ingress --group-id $nat --protocol tcp  --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $nat --protocol tcp  --port 80 --cidr $priv_sub_ip
aws ec2 authorize-security-group-ingress --group-id $nat --protocol tcp  --port 443 --cidr $priv_sub_ip
aws ec2 authorize-security-group-ingress --group-id $nat --protocol icmp  --port all --cidr $priv_sub_ip
aws ec2 authorize-security-group-ingress --group-id $nat --protocol all  --port all --source-group $priv
echo "NAT SG is created :" $nat | tee -a harish_ver3_$date.txt

#EDIT SECURITY GROUP FOR PUBLIC_SG
aws ec2 authorize-security-group-ingress --group-id $pub --protocol tcp  --port 22 --cidr 13.233.177.0/29
aws ec2 authorize-security-group-ingress --group-id $pub --protocol tcp  --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $pub --protocol tcp  --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $pub --protocol tcp  --port 22  --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $pub --protocol all  --port all --source-group $nat
echo "Public sg is created:" $pub | tee -a harish_ver3_$date.txt

#EDIT SECURITY GROUP FOR PRIVATE_SG
aws ec2 authorize-security-group-ingress --group-id $priv --protocol tcp  --port 22 --cidr  $pub_sub_ip
aws ec2 authorize-security-group-ingress --group-id $priv --protocol tcp  --port 8080 --source-group $pub
aws ec2 authorize-security-group-ingress --group-id $priv --protocol all  --port all --source-group $nat
echo "private sg is created:" $priv | tee -a harish_ver3_$date.txt

#FOR CREATING KEY PAIR-
read -p 'enter the key name' name
aws ec2 create-key-pair --key-name $name --query 'KeyMaterial' --output text > $name
sudo chmod 600 $name

#CREATING NAT INSTANCE
aws ec2 run-instances --image-id  ami-00999044593c895de --count 1 --instance-type t2.micro --key-name $name --placement AvailabilityZone=ap-south-1a --security-group-ids $nat --subnet-id $publicid  --associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$prifix-nat-ins'}]'
natid=`aws ec2 describe-instances --filters Name=tag-value,Values=$prifix-nat-ins --query Reservations[*].Instances[*].[InstanceId] --output text`
sleep 20s
aws ec2 modify-instance-attribute --instance-id=$natid --no-source-dest-check
echo "NAT Instance Created with nat instance id :" $natid  | tee -a harish_ver3_$date.txt

#CREATING PUBLIC INTANCE
aws ec2 run-instances --image-id  ami-04b1ddd35fd71475a --count 1 --instance-type t2.micro --key-name $name --placement AvailabilityZone=ap-south-1a --security-group-ids $pub --subnet-id $publicid --associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$prifix-pub-ins'}]'
pubid=`aws ec2 describe-instances --filters Name=tag-value,Values=$prifix-pub-ins --query Reservations[*].Instances[*].[InstanceId] --output text`
sleep 20s
echo "Public Instance Created with public instance id :" $pubid | tee -a harish_ver3_$date.txt

#CREATING PRIVATE INSTANCE
aws ec2 run-instances --image-id  ami-04b1ddd35fd71475a --count 1 --instance-type t2.micro --key-name $name --placement AvailabilityZone=ap-south-1a --security-group-ids $priv --subnet-id $privateid  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$prifix-priv-ins'}]'
privid=`aws ec2 describe-instances --filters Name=tag-value,Values=$prifix-priv-ins --query Reservations[*].Instances[*].[InstanceId] --output text`
sleep 20s
echo "Private Instance Created with private instance id :" $privid | tee -a harish_ver3_$date.txt


#EDIT ROUTE  FOR PRIVATE-
aws ec2 create-route --route-table-id $RT --destination-cidr-block 0.0.0.0/0 --instance-id $natid

pubip=`aws ec2 describe-instances --instance-ids $pubid --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text`
sleep 10s
private_ip=`aws ec2 describe-instances --instance-ids $privid --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text`
sleep 10s


sudo chmod 600 /home/ec2-user/$name
sudo scp -i $name /home/ec2-user/$name ec2-user@$pubip:/home/ec2-user

#for itegration of apache tomcat
ssh -i $name ec2-user@$pubip sudo yum install httpd  | tee -a harish_ver3_$date.txt
ssh -i $name ec2-user@$pubip sudo yum install -y mod_ssl  | tee -a harish_ver3_$date.txt
sudo ssh -i $name ec2-user@$pubip sudo openssl genrsa -des3 -out $prifix.key 1024 
sudo ssh -i $name ec2-user@$pubip sudo openssl req -new -key $prifix.key -out $prifix.csr
sudo ssh -i $name ec2-user@$pubip sudo cp $prifix.key $prifix.key.org 
sudo ssh -i $name ec2-user@$pubip sudo openssl rsa -in $prifix.key.org -out $SSL.key 
sudo ssh -i $name ec2-user@$pubip sudo openssl x509 -req -days 365 -in $prifix.csr -signkey $prifix.key -out $prifix.crt
sudo ssh -i $name ec2-user@$pubip sudo mv $prifix.* /etc/pki/tls/certs/

echo "certificate is created" | tee -a harish_ver3_$date.txt
sudo ssh -i $name ec2-user@$pubip sudo touch $prifix
sudo ssh -i $name ec2-user@$pubip sudo chmod 666 $prifix
sudo ssh -i $name ec2-user@$pubip "echo '<VirtualHost *:443>'>> $prifix"
sudo ssh -i $name ec2-user@$pubip "echo '	ServerAdmin webmaster@localhost'>>$prifix"
sudo ssh -i $name ec2-user@$pubip "echo '	serverName' $prifix-cloudtechner.com>>$prifix"
sudo ssh -i $name ec2-user@$pubip "echo '	ServerAlias' www.$prifix-cloudtechner.com>>$prifix"
sudo ssh -i $name ec2-user@$pubip "echo '	DocumentRoot /var/www/html/'>>$prifix"
sudo ssh -i $name ec2-user@$pubip "echo '	SSLProxyEngine on'>>$prifix"
sudo ssh -i $name ec2-user@$pubip "echo '	ProxyPass / http://"$private_ip":8080/'>>$prifix"
sudo ssh -i $name ec2-user@$pubip "echo '	ProxyPassReverse / http://"$private_ip":8080/'>>$prifix"
sudo ssh -i $name ec2-user@$pubip "echo '	'>>$prifix"
sudo ssh -i $name ec2-user@$pubip "echo '	SSLEngine on'>>$prifix"
sudo ssh -i $name ec2-user@$pubip "echo '	SSLCertificateFile /etc/pki/tls/certs/'$prifix'.crt'>>$prifix"
sudo ssh -i $name ec2-user@$pubip "echo '	SSLCertificateKeyFile /etc/pki/tls/certs/'$prifix'.key'>>$prifix" 
sudo ssh -i $name ec2-user@$pubip "echo '</VirtualHost>'>>$prifix"
echo "configuration file is created" | tee -a harish_ver3_$date.txt
sudo ssh -i $name ec2-user@$pubip sudo mv $prifix /etc/httpd/conf.d/$prifix.conf
sudo ssh -i $name ec2-user@$pubip sudo chmod 666 /etc/httpd/conf.d/$prifix.conf
sudo ssh -i $name ec2-user@$pubip sudo chmod 666 /etc/hosts
sudo ssh -i $name ec2-user@$pubip sudo "echo $pubip' '$prifix-cloudtechner.com>>/etc/hosts"
sudo ssh -i $name ec2-user@$pubip sudo chmod 644 /etc/hosts
sudo ssh -i $name ec2-user@$pubip sudo systemctl start httpd
sudo ssh -i $name ec2-user@$pubip ssh -o StrictHostKeyChecking=no ec2-user@$private_ip
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip sudo yum install java
echo "java is intalled" | tee -a harish_ver3_$date.txt
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip sudo wget  https://downloads.apache.org/tomcat/tomcat-8/v8.5.61/bin/apache-tomcat-8.5.61.tar.gz
echo "apache-tomcat is istalled" | tee -a harish_ver3_$date.txt
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip sudo tar -xzvf /home/ec2-user/apache-tomcat-8.5.61.tar.gz
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip sudo chmod 755 /home/ec2-user/apache-tomcat-8.5.61/bin
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip sudo chmod 755 /home/ec2-user/apache-tomcat-8.5.61/webapps/
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip wget https://get.jenkins.io/war/2.272/jenkins.war
echo "jenkins is installed" | tee -a harish_ver3_$date.txt
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip sudo mv /home/ec2-user/jenkins.war /home/ec2-user/apache-tomcat-8.5.61/webapps/
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip cd /apache-tomcat-8.5.61/bin/ $$ sudo sh startup.sh
echo "tomcat is started" | tee -a harish_ver3_$date.txt
#sudo ssh -i PR1 ec2-user@$public_ip sudo ssh -i /home/ec2-user/example ec2-user@$private_ip sudo chmod 755 /apache-tomcat-8.5.61/bin/
