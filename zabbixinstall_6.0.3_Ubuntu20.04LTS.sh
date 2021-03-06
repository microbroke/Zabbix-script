#!/bin/bash

# Installation of Zabbix 5.0 on Ubuntu 18.04 LTS
# Some instruction from: 
# https://www.zabbix.com/download?zabbix=5.0&os_distribution=ubuntu&os_version=18.04_bionic&db=mysql&ws=apache

# Stop on error
set -e
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

# Set Timezone to Europe/Stockholm (timedatectl list-timezones)
sudo timedatectl set-timezone Europe/Stockholm

# Mysql Zabbix user password
read -p "Set a password for the mysql zabbix user:" mysqlzabbixpw

# Installs mysql
apt install mysql-server

# a. Add exclusion for zabbix-package
#touch /etc/dpkg/dpkg.cfg.d/excludes
#echo "path-include=/usr/share/doc/zabbix*" >> /etc/dpkg/dpkg.cfg.d/excludes

# b. Install Zabbix repository
wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-3+ubuntu20.04_all.deb
dpkg -i zabbix-release_6.0-3+ubuntu20.04_all.deb
apt update

# c. Install Zabbix server, frontend, agent
apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent zabbix-sql-scripts

# d. Create initial database
sudo mysql -uroot -e "create database zabbix character set utf8 collate utf8_bin;"
sudo mysql -uroot -e "create user zabbix@localhost identified by '${mysqlzabbixpw}';"
sudo mysql -uroot -e "grant all privileges on zabbix.* to zabbix@localhost;"

# On Zabbix server host import initial schema and data. You will be prompted to enter your newly created password.
#zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p$mysqlzabbixpw zabbix
# create.sql.gz is no longer available and have moved to server.sql.gz contained within the application zabbix-sql-scripts
zcat /usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -p$mysqlzabbixpw zabbix

# e. Configure the database for Zabbix server
sed -i "s*# DBPassword=*DBPassword=$mysqlzabbixpw*" /etc/zabbix/zabbix_server.conf
sed -i 's*# DBHost=localhost*DBHost=localhost*' /etc/zabbix/zabbix_server.conf

# f. Configure PHP for Zabbix frontend
# Edit file /etc/zabbix/apache.conf, uncomment and set the right timezone for you.
sed -i 's*# php_value date.timezone Europe/Riga*php_value date.timezone Europe/Stockholm*' /etc/zabbix/apache.conf

# g. Start Zabbix server and agent processes
# Start Zabbix server and agent processes and make it start at system boot.
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2
