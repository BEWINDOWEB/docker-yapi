#!/bin/sh
# args
basepath=$(cd `dirname $0`; pwd)
datapath=$basepath
olddatapath=$basepath'/backupdata7days'
mdpath="/usr/bin/mongodump"
databasename="yapi"
user="yapidba"
password="123456"
hostname="localhost"
port="27017"
 
# move old data to olddatapath
if [ "`ls -A ${datapath}`" != "" ];then
    mv ${datapath}'/'*${databasename}* ${olddatapath} 2>/dev/null
fi
 
# gen new backup
now=$(date +"%Y-%m-%d")
file=${datapath}'/'${databasename}-$now
${mdpath} -h${hostname}:${port} -u${user} -p${password} -d${databasename} -o${file}
#echo ${mdpath} -h${hostname}:${port} -u${user} -p${password} -d${databasename} -o${file}
 
# clean up over 7 days
sevendays=$(date -d -7day +"%Y-%m-%d")
if [ -d ${olddatapath}'/'$databasename'-'$sevendays ];then
    rm -rf ${olddatapath}'/'$databasename'-'$sevendays
fi
