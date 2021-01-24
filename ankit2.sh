#!/bin/bash
aws configure

date=`TZ=IST-5:30 date +%F_%T`
#FOR CREATING VPC
read -p 'enter the ipv4 address for vpc' IP
vpcid=`aws ec2 create-vpc --cidr-block $IP --query Vpc.VpcId --output text`
read -p 'enter the vpc name'  vpc_name
aws ec2 create-tags --resources $vpcid --tags Key=Name,Value=$vpc_name
echo "VPC created with VPC ID :" $vpcid | tee -a harish_ver3_$date.txt

#FOR CREATING PUBLIC SUBNET
read -p 'enter the public subnet ip' pub_sub_ip
publicid=`aws ec2 create-subnet --vpc-id $vpcid --cidr-block $pub_sub_ip --availability-zone ap-south-1a --query Subnet.SubnetId --output text`
read -p 'enter the public subnet name' pub_sub_name
aws ec2 create-tags --resources $publicid --tags Key=Name,Value=$pub_sub_name
echo "Publicsubnet created with subnet id :" $publicid | tee -a harish_ver3_$date.txt

#FOR PRIVATE SUBNET
read -p 'enter the private subnet ip'  priv_sub_ip
privateid=`aws ec2 create-subnet --vpc-id $vpcid --cidr-block $priv_sub_ip --availability-zone ap-south-1a --query Subnet.SubnetId --output text`
read -p 'enter the private subnet name' priv_sub_name
aws ec2 create-tags --resources $privateid  --tags Key=Name,Value=$priv_sub_name
echo "Private subnet created with sunnet id :" $privateid | tee -a harish_ver3_$date.txt

#FOR CREATING INTERNET GATEWAY
igw=`aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text`
aws ec2 attach-internet-gateway --internet-gateway-id $igw --vpc-id  $vpcid
read -p 'enter the name of internet gateway' igwname
aws ec2 create-tags --resources $igw  --tags Key=Name,Value=$igwname
echo "Internet gateway created with igw id :" $igw | tee -a harish_ver3_$date.txt

#EDIT ROUTE TABLE-
read -p 'enter the vpc route table id' vpc_rtb
aws ec2 create-route --route-table-id $vpc_rtb --destination-cidr-block 0.0.0.0/0 --gateway-id $igw

#CREATE SECURITY GROUP-
read -p 'enter the NAT security group name' NAT_SG_NAME
nat=`aws ec2 create-security-group --group-name $NAT_SG_NAME --description "My nat security group" --vpc-id  $vpcid --query GroupId --output text`
read -p 'enter the NAT sg name' NAT_sg_name
aws ec2 create-tags --resources $nat --tags Key=Name,Value=$NAT_sg_name
echo "natsg created with natsg id :" $nat | tee -a harish_ver3_$date.txt

#for creating pivate security group-
read -p 'enter the private security group name' priv_SG
priv=`aws ec2 create-security-group --group-name $priv_SG --description "My CLI security group" --vpc-id  $vpcid --query GroupId --output text`
read -p 'enter the private sg name' priv_sg_name
aws ec2 create-tags --resources $priv --tags Key=Name,Value=$priv_sg_name
echo "Private Securitygroup Created with sgid :" $priv | tee -a harish_ver3_$date.txt

#FOR CREATING THE PUBLIC SECURITY GROUP-
read -p 'enter the public security group name' pub_SG
pub=`aws ec2 create-security-group --group-name $pub_SG --description "My CLI security group" --vpc-id  $vpcid --query GroupId --output text`
read -p 'enter the public sg name' pub_sg_name
aws ec2 create-tags --resources $pub --tags Key=Name,Value=$pub_sg_name
echo "Public Security group created with public sg id :" $pub  | tee -a harish_ver3_$date.txt

#CREATE ROUTE TABLE -
RT=`aws ec2 create-route-table --vpc-id $vpcid  --query RouteTable.RouteTableId --output text`
echo $RT
read -p 'enter the route table name' RT_NAME
aws ec2 create-tags    --resources $RT --tags Key=Name,Value=$RT_NAME
echo "route table created with routetable id :" $RT  | tee -a harish_ver3_$date.txt

#FOR SUBNET ASSOCIATION-
aws ec2 associate-route-table --route-table-id $RT --subnet-id $privateid

#EDIT SECURITY GROUP FOR NAT_SG
aws ec2 authorize-security-group-ingress --group-id $nat --protocol tcp  --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $nat --protocol tcp  --port 80 --cidr $priv_sub_ip
aws ec2 authorize-security-group-ingress --group-id $nat --protocol tcp  --port 443 --cidr $priv_sub_ip
aws ec2 authorize-security-group-ingress --group-id $nat --protocol icmp  --port all --cidr $priv_sub_ip
aws ec2 authorize-security-group-ingress --group-id $nat --protocol all  --port all --source-group $priv


#EDIT SECURITY GROUP FOR PUBLIC_SG
aws ec2 authorize-security-group-ingress --group-id $pub --protocol tcp  --port 22 --cidr 13.233.177.0/29
aws ec2 authorize-security-group-ingress --group-id $pub --protocol tcp  --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $pub --protocol tcp  --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $pub --protocol tcp  --port 22  --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $pub --protocol all  --port all --source-group $nat


#EDIT SECURITY GROUP FOR PRIVATE_SG
aws ec2 authorize-security-group-ingress --group-id $priv --protocol tcp  --port 22 --cidr  $pub_sub_ip
aws ec2 authorize-security-group-ingress --group-id $priv --protocol tcp  --port 8080 --source-group $pub
aws ec2 authorize-security-group-ingress --group-id $priv --protocol all  --port all --source-group $nat


#FOR CREATING KEY PAIR-
read -p 'enter the key name' name
aws ec2 create-key-pair --key-name $name --query 'KeyMaterial' --output text > $name
sudo chmod 600 $name

#CREATING NAT INSTANCE
read -p 'enter the nat instance name' nat_ins_name
aws ec2 run-instances --image-id  ami-00999044593c895de --count 1 --instance-type t2.micro --key-name $name --placement AvailabilityZone=ap-south-1a --security-group-ids $nat --subnet-id $publicid  --associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$nat_ins_name'}]'
natid=`aws ec2 describe-instances --filters Name=tag-value,Values=$nat_ins_name --query Reservations[*].Instances[*].[InstanceId] --output text`
sleep 20s
aws ec2 modify-instance-attribute --instance-id=$natid --no-source-dest-check
echo "NAT Instance Created with nat instance id :" $natid  | tee -a harish_ver3_$date.txt

#CREATING PUBLIC INTANCE
read -p 'enter the public instance name' pub_ins_name
aws ec2 run-instances --image-id  ami-04b1ddd35fd71475a --count 1 --instance-type t2.micro --key-name $name --placement AvailabilityZone=ap-south-1a --security-group-ids $pub --subnet-id $publicid --associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$pub_ins_name'}]'
pubid=`aws ec2 describe-instances --filters Name=tag-value,Values=$pub_ins_name --query Reservations[*].Instances[*].[InstanceId] --output text`
sleep 20s
aws ec2 create-tags --resources $pubid  --tags Key=Name,Value=$pub_ins_name
echo "Public Instance Created with public instance id :" $pubid | tee -a harish_ver3_$date.txt
#CREATING PRIVATE INSTANCE
read -p 'enter the private instance name' priv_ins_name
aws ec2 run-instances --image-id  ami-04b1ddd35fd71475a --count 1 --instance-type t2.micro --key-name $name --placement AvailabilityZone=ap-south-1a --security-group-ids $priv --subnet-id $privateid  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$priv_ins_name'}]'
privid=`aws ec2 describe-instances --filters Name=tag-value,Values=$priv_ins_name --query Reservations[*].Instances[*].[InstanceId] --output text`
sleep 20s
echo "Private Instance Created with private instance id :" $privid | tee -a harish_ver3_$date.txt


#EDIT ROUTE  FOR PRIVATE-
aws ec2 create-route --route-table-id $RT --destination-cidr-block 0.0.0.0/0 --instance-id $natid



read -p 'enter the PR_PUB_INS PUBLIC IP FOR SSH' pubip
read -p 'enter the PR_PRIV_INS PRIVATE IP FOR SSH' private_ip
sudo chmod 600 /home/ec2-user/$name
sudo scp -i $name /home/ec2-user/$name ec2-user@$pubip:/home/ec2-user

#for itegration of apache tomcat
ssh -i $name ec2-user@$pubip sudo yum install httpd
ssh -i $name ec2-user@$pubip sudo yum install -y mod_ssl
read -p 'enter the key name' SSL
sudo ssh -i $name ec2-user@$pubip sudo openssl genrsa -des3 -out $SSL.key 1024 
sudo ssh -i $name ec2-user@$pubip sudo openssl req -new -key $SSL.key -out $SSL.csr
sudo ssh -i $name ec2-user@$pubip sudo cp $SSL.key $SSL.key.org 
sudo ssh -i $name ec2-user@$pubip sudo openssl rsa -in $SSL.key.org -out $SSL.key
sudo ssh -i $name ec2-user@$pubip sudo openssl x509 -req -days 365 -in $SSL.csr -signkey $SSL.key -out $SSL.crt
sudo ssh -i $name ec2-user@$pubip sudo mv $SSL.* /etc/pki/tls/certs/
read -p 'enter configuration file name' exam
read -p 'enter server name' ser
read -p 'Enter serverAlias Name' serAli
sudo ssh -i $name ec2-user@$pubip sudo touch $exam
sudo ssh -i $name ec2-user@$pubip sudo chmod 666 $exam
sudo ssh -i $name ec2-user@$pubip "echo '<VirtualHost *:443>'>> $exam"
sudo ssh -i $name ec2-user@$pubip "echo '	ServerAdmin webmaster@localhost'>>$exam"
sudo ssh -i $name ec2-user@$pubip "echo '	serverName' $ser>>$exam"
sudo ssh -i $name ec2-user@$pubip "echo '	ServerAlias' $serAli>>$exam"
sudo ssh -i $name ec2-user@$pubip "echo '	DocumentRoot /var/www/html/'>>$exam"
sudo ssh -i $name ec2-user@$pubip "echo '	SSLProxyEngine on'>>$exam"
sudo ssh -i $name ec2-user@$pubip "echo '	ProxyPass / http://"$private_ip":8080/'>>$exam"
sudo ssh -i $name ec2-user@$pubip "echo '	ProxyPassReverse / http://"$private_ip":8080/'>>$exam"
sudo ssh -i $name ec2-user@$pubip "echo '	'>>$exam"
sudo ssh -i $name ec2-user@$pubip "echo '	SSLEngine on'>>$exam"
sudo ssh -i $name ec2-user@$pubip "echo '	SSLCertificateFile /etc/pki/tls/certs/'$SSL'.crt'>>$exam"
sudo ssh -i $name ec2-user@$pubip "echo '	SSLCertificateKeyFile /etc/pki/tls/certs/'$SSL'.key'>>$exam" 
sudo ssh -i $name ec2-user@$pubip "echo '</VirtualHost>'>>$exam"
sudo ssh -i $name ec2-user@$pubip sudo mv $exam /etc/httpd/conf.d/$exam.conf
sudo ssh -i $name ec2-user@$pubip sudo chmod 666 /etc/httpd/conf.d/$exam.conf
sudo ssh -i $name ec2-user@$pubip sudo chmod 666 /etc/hosts
sudo ssh -i $name ec2-user@$pubip sudo "echo $pubip' '$ser>>/etc/hosts"
sudo ssh -i $name ec2-user@$pubip sudo chmod 644 /etc/hosts
sudo ssh -i $name ec2-user@$pubip sudo systemctl start httpd
sudo ssh -i $name ec2-user@$pubip ssh -o StrictHostKeyChecking=no ec2-user@$private_ip
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip sudo yum install java
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip sudo wget  https://downloads.apache.org/tomcat/tomcat-8/v8.5.61/bin/apache-tomcat-8.5.61.tar.gz
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip sudo tar -xzvf /home/ec2-user/apache-tomcat-8.5.61.tar.gz
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip sudo chmod 755 /home/ec2-user/apache-tomcat-8.5.61/bin
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip sudo chmod 755 /apache-tomcat-8.5.61/webapps
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip wget https://get.jenkins.io/war/2.272/jenkins.war
sudo ssh -i $name ec2-user@$pubip ssh -i $name ec2-user@$private_ip  mv /home/ec2-user/jenkins.war /home/ec2-user/apache-tomcat-8.5.61/webapps/

#sudo ssh -i PR1 ec2-user@$public_ip sudo ssh -i /home/ec2-user/example ec2-user@$private_ip sudo chmod 755 /apache-tomcat-8.5.61/bin/
