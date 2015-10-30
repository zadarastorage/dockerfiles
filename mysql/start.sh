#!/usr/bin/env bash

service ssh start

#
# Note these will map to the pool storage if a volume is not mapped to /mnt/mysql
#

if [ ! -d /mnt/mysql/data ]; then
  mkdir -p /mnt/mysql/data
  chown -R mysql:mysql /mnt/mysql
  mysql_install_db --user=mysql --ldata=/mnt/mysql/data/
fi

if [ ! -d /mnt/mysql/log ]; then
  mkdir -p /mnt/mysql/log
  chown -R mysql:mysql /mnt/mysql
fi

mysqld_safe 

tail -f /mnt/mysql/log/error.log

