#!/usr/bin/env bash

wget http://dev.mysql.com/get/mysql-apt-config_0.8.11-1_all.deb
echo mysql-apt-config mysql-apt-config/select-server select mysql-5.7 | sudo debconf-set-selections
sudo dpkg -i mysql-apt-config_0.8.11-1_all.deb
sudo apt-get update -q
sudo apt-get install -q -y -o Dpkg::Options::=--force-confnew mysql-server
sudo mysql_upgrade

set -x
set -e
sudo  mysqld_safe --skip-grant-tables &
sleep 4
sudo mysql -e "use mysql; update user set authentication_string=PASSWORD('') where user='root'; update user set plugin='mysql_native_password'; FLUSH PRIVILEGES;"
sudo kill -9 `sudo cat /var/lib/mysql/mysqld_safe.pid`
sudo kill -9 `sudo cat /var/run/mysqld/mysqld.pid`
sudo service mysql restart
sleep 4
