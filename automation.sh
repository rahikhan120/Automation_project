#!/bin/bash
s3_bucket='upgrad-rahila'
myname='rahila'
timestamp=$(date +"%d%m%Y-%H%M%S")
logtype='httpd-logs'
type='tar'
sudo apt update -y
if which apache2 > /dev/null ; then
	echo "already installed : $(dpkg-query -W -f='${Version}\n' apache2)"
else
   echo "Installing"
sudo apt install apache2 -y
fi
if ! pidof apache2 > /dev/null
then
    echo "apache2 is not running !! restarting"
    systemctl restart apache2 
else
	echo "apache2 is running"
	service apache2 status |grep running
fi
if [[ $(systemctl list-unit-files | grep apache2.service | awk '{ print $2}') ==  "enabled" ]] ; then
	echo "enabled"
else 
	echo "enabling"
	systemctl enable apache2 
fi
cd /var/log/apache2 && tar -czf $myname-$logtype-${timestamp}.$type *.log && 
mv $myname-$logtype-${timestamp}.$type /tmp/
echo "done collecting logs"
aws s3 	cp /tmp/$myname-$logtype-${timestamp}.$type s3://$s3_bucket/$myname-$logtype-${timestamp}.$type
path="/var/www/html"
if [[  -s ${path}/inventory.html ]]
then
	echo "file found"
else 
	echo -e 'Log Type\t-\tTime Created\t-\tType\t-\tSize' > ${path}/inventory.html
fi
size=$(du -h /tmp/$myname-httpd-logs-${timestamp}.tar | awk '{print $1}')
if [[ -f ${path}/inventory.html ]] 
then
	echo -e "$logtype\t-\t${timestamp}\t-\t$type\t-\t${size}" >> ${path}/inventory.html
fi
echo "======================================> setting cronjob <======================================"
if [ -s "/etc/cron.d/automation" ]
then
echo "File is found"
else
  cat >>/etc/cron.d/automation << EOF
   0 0 * * *  /root/Automation_project/automation.sh
EOF
fi


