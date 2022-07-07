#!/bin/bash
# Installation of Opsgenie Zabbix Plugin Integration

# Stop on error
set -e
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

# Variabel for API-KEY
read -p "Write the API-KEY from opsgenie integration:" apikey

# Password for the admin user of zabbix
read -p "Write the password for the Zabbix user Admin:" zabbixadminpw

# Next Install opsgenie plugin OEC
wget https://github.com/opsgenie/oec-scripts/releases/download/Zabbix-1.1.6_oec-1.1.3/opsgenie-zabbix_1.1.6_amd64.deb
dpkg -i opsgenie-zabbix_1.1.6_amd64.deb

# Replace the config in /home/opsgenie/oec/conf/config.json
sed -i "s*\"apiKey\": \"<API_KEY>\",*\"apiKey\": \"$apikey\",*" /home/opsgenie/oec/conf/config.json
sed -i "s*\"password\": \"zabbix\"*\"password\": \"$zabbixadminpw\"*" /home/opsgenie/oec/conf/config.json
sed -i "s*\"filepath\": \"/home/opsgenie/oec/scripts/actionExecutor.py\",*\"filepath\": \"/home/opsgenie/oec/scripts/actionExecutorForZabbix4.py\",*" /home/opsgenie/oec/conf/config.json

# Start oec service and make it start at system boot.
systemctl restart oec
systemctl enable oec

# try the integration:
# sudo /home/opsgenie/oec/opsgenie-zabbix/send2opsgenie -triggerName='zabbix test alert' -triggerStatus='PROBLEM'