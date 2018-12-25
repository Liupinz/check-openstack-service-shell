#!/bin/bash

source /root/admin-openrc

mkdir /root/check
now_date=$(date +%Y-%m-%d)
check_file=/root/check/$now_date"_check_service"
ifconfig_1=/root/check/$now_date"_ifconfig_one"
ifconfig_2=/root/check/$now_date"_ifconfig_two"
> $check_file
> $ifconfig_1
> $ifconfig_2

#check mariadb service
mariadb_service=`systemctl status mariadb.service | grep Active | awk '{print $2}'`
if [ $mariadb_service != active ];then
	echo "Important! You should check the mariadb service"
        echo "You should check the mariadb service" >> $check_file
else
	echo "The mariadb status is $mariadb_service"
fi

#check rabbitmq-server
rabbitmq_state=`systemctl status rabbitmq-server | grep Active | awk '{print $2}'`
if [ $rabbitmq_state != active ];then
	echo "Important! You should check the rabbitmq-server"
        echo "You should check the rabbitmq-server" >> $check_file
else
	echo "The rabbitmq status is $rabbitmq_state"
fi


#check httpd service
httpd_state=`systemctl status httpd | grep Active | awk '{print $2}'`
if [ $httpd_state != active ];then
        echo "You should check the httpd service" >> $check_file
else
	echo "The httpd status is $httpd_state"
fi

#check / use
use=$(df -h | grep -w "/" |awk '{print int($5)}')
limit=80
if [ "$use" -gt "$limit" ];then
	echo"Important! You should check the use of /"
	echo"Important! You should check the use of /" >> $check_file
else
	echo "The use of / is $use%"
fi

#check memory
free_memory=$(free -h | grep Mem | awk '{print $4}')
echo "The free memory is $free_memory"

#show cpu load average
load_average=$(uptime | awk '{print $8,$9,$10,$11,$12}')
echo "The load average is $load_average"

#check nova service
nova service-list
for nova_state in `nova service-list | awk '{print $12}' | grep -Ev "State|^$"`
do
	if [ $nova_state != up ];then
		echo "You should check the nova service." >> $check_file
	fi
done

#check neutron service
neutron agent-list
for neutron_state in `neutron agent-list | awk -F '|' '{print $6}' | grep -Ev "alive|^$"`
do
	if [ $neutron_state == xxx ];then
		echo "You should check the neutron service" >> $check_file 
	fi
done

#check cinder service
cinder service-list
for cinder_state in `cinder service-list | awk '{print $10}' | grep -Ev "State|^$"`
do
	if [ $cinder_state != up ];then
		echo "You should check the cinder service" >> $check_file 
	fi
done

#check ifconfig -s
echo  `ifconfig -s | awk '{print $4}'` >> $ifconfig_1
echo  `ifconfig -s | awk '{print $5}'` >> $ifconfig_1
echo  `ifconfig -s | awk '{print $8}'` >> $ifconfig_1
echo  `ifconfig -s | awk '{print $9}'` >> $ifconfig_1       

sleep 60

echo  `ifconfig -s | awk '{print $4}'` >> $ifconfig_2
echo  `ifconfig -s | awk '{print $5}'` >> $ifconfig_2
echo  `ifconfig -s | awk '{print $8}'` >> $ifconfig_2
echo  `ifconfig -s | awk '{print $9}'` >> $ifconfig_2           

diff $ifconfig_1 $ifconfig_2 > /dev/null
if [ $? != 0 ];then
	echo "You should check the ifconfig -s status" >> $check_file
fi

#input the result
if test -s $check_file ;then
 	echo "You should check the $check_file file."
else
	echo "Everything is ok!"
fi


