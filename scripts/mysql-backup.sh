#!/bin/bash

DATABASE="zabbix"

EXCLUDE_TABLES="
	trends
	trends_uint
	history_text
	history_str
	history
	history_uint
	history_log
"

IGNORE_CMD=""
for table in $EXCLUDE_TABLES; do
	IGNORE_CMD+=" --ignore-table=${DATABASE}.${table}"
done

# NAME & LOCATION
year=$(date +%Y)
week=$(date +%W)
month=$(date +%m)
day=$(date +%d)
hour=$(date +%H)

mkdir -p /root/backup/data/hour/$hour
mkdir -p /root/backup/data/day/$day
mkdir -p /root/backup/data/week/$week
mkdir -p /root/backup/data/month/$month
mkdir -p /root/backup/data/year/$year

rm /root/backup/data/hour/$hour/zabbix-db-structure.sql.gz
rm /root/backup/data/hour/$hour/zabbix-db-content.sql.gz

# Dump database structure
mysqldump -u dump $DATABASE --single-transaction --no-data --routines | gzip > /root/backup/data/hour/$hour/zabbix-db-structure.sql.gz

# Dump database content
mysqldump -u dump $DATABASE --single-transaction --no-create-info --skip-triggers ${IGNORE_CMD} | gzip > /root/backup/data/hour/$hour/zabbix-db-content.sql.gz


ln -f /root/backup/data/hour/$hour/zabbix-db-structure.sql.gz /root/backup/data/day/$day/zabbix-db-structure.sql.gz
ln -f /root/backup/data/hour/$hour/zabbix-db-structure.sql.gz /root/backup/data/week/$week/zabbix-db-structure.sql.gz
ln -f /root/backup/data/hour/$hour/zabbix-db-structure.sql.gz /root/backup/data/month/$month/zabbix-db-structure.sql.gz
ln -f /root/backup/data/hour/$hour/zabbix-db-structure.sql.gz /root/backup/data/year/$year/zabbix-db-structure.sql.gz

ln -f /root/backup/data/hour/$hour/zabbix-db-content.sql.gz /root/backup/data/day/$day/zabbix-db-content.sql.gz
ln -f /root/backup/data/hour/$hour/zabbix-db-content.sql.gz /root/backup/data/week/$week/zabbix-db-content.sql.gz
ln -f /root/backup/data/hour/$hour/zabbix-db-content.sql.gz /root/backup/data/month/$month/zabbix-db-content.sql.gz
ln -f /root/backup/data/hour/$hour/zabbix-db-content.sql.gz /root/backup/data/year/$year/zabbix-db-content.sql.gz
