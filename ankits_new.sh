#!/bin/bash
read -p 'enter the PUBLIC IP FOR SSH' pubip
read -p 'enter the  PRIVATE IP FOR SSH' private_ip
#sudo chmod 600 siba
#sudo scp -i siba /home/ec2-user/siba ec2-user@$pubip:/home/ec2-user/

#for itegration of apache tomcat
#ssh -i siba ec2-user@$pubip sudo yum install httpd
#ssh -i siba ec2-user@$pubip sudo yum install -y mod_ssl
read -p 'enter the key name' SSL
ssh -i siba ec2-user@13.235.115.216 sudo openssl genrsa -des3 -out $SSL.key 1024 
ssh -i siba ec2-user@$pubip sudo openssl req -new -key $SSL.key -out $SSL.csr
ssh -i siba ec2-user@$pubip sudo cp $SSL.key $SSL.key.org
ssh -i siba ec2-user@$pubip sudo openssl rsa -in $SSL.key.org -out $SSL.key
ssh -i siba ec2-user@$pubip sudo openssl x509 -req -days 365 -in $SSL.csr -signkey $SSL.key -out $SSL.crt
ssh -i siba ec2-user@$pubip sudo mv $SSL.* /etc/pki/tls/certs/
read -p 'Enter configuration file name' exam
read -p 'Enter server name' ser
read -p 'Enter serverAlias Name' serAli
ssh -i siba ec2-user@$pubip sudo touch $exam
ssh -i siba ec2-user@$pubip sudo chmod 666 $exam
ssh -i siba ec2-user@$pubip "echo '<VirtualHost *:443>'>> $exam"
ssh -i siba ec2-user@$pubip "echo '          ServerAdmin webmaster@localhost'>>$exam"
ssh -i siba ec2-user@$pubip "echo '          serverName' $ser>>$exam"
ssh -i siba ec2-user@$pubip "echo '          ServerAlias' $serAli>>$exam"
ssh -i siba ec2-user@$pubip "echo '          DocumentRoot /var/www/html/'>>$exam"
ssh -i siba ec2-user@$pubip "echo '          SSLProxyEngine on'>>$exam"
ssh -i siba ec2-user@$pubip "echo '          ProxyPass / http://"$private_ip":8080/'>>$exam"
ssh -i siba ec2-user@$pubip "echo '          ProxyPassReverse / http://"$private_ip":8080/'>>$exam"
ssh -i siba ec2-user@$pubip "echo '          '>>$exam"
ssh -i siba ec2-user@$pubip "echo '          SSLEngine on'>>$exam"
ssh -i siba ec2-user@$pubip "echo '          SSLCertificateFile /etc/pki/tls/certs/'$SSL'.crt'>>$exam"
ssh -i siba ec2-user@$pubip "echo '          SSLCertificateKeyFile /etc/pki/tls/certs/'$SSL'.key'>>$exam" 
ssh -i siba ec2-user@$pubip "echo '</VirtualHost>'>>$exam"
ssh -i siba ec2-user@$pubip sudo chmod 666 /etc/httpd/conf.d/$exam.conf
ssh -i siba ec2-user@$pubip sudo mv $exam /etc/httpd/conf.d/$exam.conf
sudo ssh -i siba ec2-user@$pubip sudo chmod 666 /etc/hosts
sudo ssh -i siba ec2-user@$pubip "echo  $pubip'   '$ser>>/etc/hosts"
sudo ssh -i siba ec2-user@$pubip sudo chmod 644 /etc/hosts
sudo ssh -i siba ec2-user@$pubip sudo systemctl restart httpd
ssh -i siba ec2-user@$pubip ssh -o StrictHostKeyChecking=no ec2-user@$private_ip
sudo ssh -i siba ec2-user@$pubip sudo ssh -i siba ec2-user@$private_ip sudo yum install java
sudo ssh -i siba ec2-user@$pubip sudo ssh -i siba ec2-user@$private_ip sudo wget https://mirrors.estointernet.in/apache/tomcat/tomcat-8/$
sudo ssh -i siba ec2-user@$pubip sudo ssh -i siba ec2-user@$private_ip sudo tar -xzvf /home/ec2-user/apache-tomcat-8.5.61.tar.gz 

#sudo ssh -i $name ec2-user@$pub_ip sudo ssh -i ABCD ec2-user@$private_ip sudo chmod 755 /apache-tomcat-8.5.61/webapps/
#sudo ssh -i $name ec2-user@$pub_ip sudo ssh -i ABCD ec2-user@$private_ip  mv /home/ec2-user/jenkins.war /home/ec2-user/apache-tomcat-8.5.6$

#sudo ssh -i PR1 ec2-user@$public_ip sudo ssh -i /home/ec2-user/example ec2-user@$private_ip sudo chmod 755 /apache-tomcat-8.5.61/bin/
