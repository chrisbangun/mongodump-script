#!/bin/bash
#ACB

BACKUPS_DIR="/home/ubuntu/mongodump/dump/backup"
SINGLE_BACKUP_DIR="/home/ubuntu/mongodump/dump"
TIMESTAMP=`date +%F-%H:%M:%S`
BACKUP_NAME="$APP_NAME-$TIMESTAMP"
FILE="/var/traveloka/running/mongodump-scripts/databases-to-dump.txt"
CurrentTime=`date +"%r"`
mongo_dump="/usr/bin/mongodump"
LogFile="/var/traveloka/running/mongodump-scripts/mongo-backup.log"
dumpAll=true
found=false

#echo $? #the exit status of the last command executed

echo "mongodump.sh was ran at $TIMESTAMP" >> /var/traveloka/running/mongodump-scripts/cron-log.txt


while IFS='' read -r line || [[ -n "$line" ]]; do
  if [ "$#" -ge 1 ]; then
    dumpAll=false
    if [ "$1" == $line ]; then
      echo "$line"
      found=true
      command=`$mongo_dump --db $line --out $SINGLE_BACKUP_DIR`
      if [ $? -ne 0 ]; then
        echo "[Error log $TIMESTAMP] $command" >> $LogFile
        exit
      else
        APP_NAME="$line"
        BACKUP_NAME="$APP_NAME-$TIMESTAMP"
        tar -czvf $SINGLE_BACKUP_DIR/$BACKUP_NAME.tar.gz $BACKUPS_DIR/$line
      fi
      break
    fi
  else
    echo "creating a dump for $line..."
    command=`$mongo_dump --db $line --out $BACKUPS_DIR`
    if [ $? -ne 0 ]; then
      echo "$CurrentTime: Some Erros occur while back up"
      echo "[Error log $TIMESTAMP]  $command" >> $LogFile
      exit
    fi
  fi
done < "$FILE"

if [ $dumpAll == false ] && [ $found == false ]; then
  echo "$1 cannot be found. It may does not exist in your mongo"
  exit
fi
#if $dumpAll ; then
#  echo "zipping all dumped databases"
#  cd $BACKUPS_DIR
#  tar -czf mongodump-all.tgz $BACKUPS_DIR  
#fi
