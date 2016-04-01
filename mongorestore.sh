#!/bin/bash

#ACB
BACKUP_DIR="/home/ubuntu/mongodump/dump/backup"
LOG_FILE="/path/to/log/mongorestore_script.log"

mongo_restore()
{
  echo "restoring dumped database(s)"
  echo "ssh $staging mongorestore --db $fileName --drop /home/ubuntu/mongodump/dump/backup/"
  echo "do something $staging $fileName"
}

copy_and_extract_db()
{
  mkdirCommand=`ssh $staging mkdir -p /home/ubuntu/mongodump/dump/backup`
  if [ $? -ne 0 ]; then
    echo "error when creating dir /home/ubuntu/mongodump/dump/backup"
    exit
  fi
 
  if $dumpAll; then
    scpCommand=`scp -3 staging06:/home/ubuntu/mongodump/dump/$tar_name $staging:/home/ubuntu/mongodump/dump/backup`
    if [ $? -ne 0 ]; then
      echo "error when copying file between staging06 and $staging"
      echo "$scpCommand"
      exit
    else
      echo "file copied..."
      echo "...extracting file..."
      tarCommand=`ssh $staging tar xvf /home/ubuntu/mongodump/dump/$tar_name --strip-components=5 -C /home/ubuntu/mongodump/dump/backup/`
      if [ $? -ne 0 ]; then
        echo "Error while extracting $tar_name"
        echo "$tarCommand"
        exit
      else
        echo"$tarCommand"
        echo "Files have been extracted successfully"
        deleteTarFile=`ssh $staging rm /home/ubuntu/mongodump/dump/backup/$tar_name`
        fileName="${tar_name%%.*}"
        mongo_restore $dumpAll $staging $fileName
      fi
    fi
    exit
  else
    scpCommand=`scp -3 staging06:/home/ubuntu/mongodump/dump/backup/$tar_name $staging:/home/ubuntu/mongodump/dump/backup`
    if [ $? -ne 0 ]; then
      echo "error when copying file between staging06 and $staging"
      echo "$scpCommand"
      exit
    else
      echo "file copied..."
      echo "...extracting file:$tar_name"
      tarCommand=`ssh $staging tar xvf /home/ubuntu/mongodump/dump/backup/$tar_name --strip-components=5 -C /home/ubuntu/mongodump/dump/backup/`
      if [ $? -ne 0 ]; then
        echo "Error while extracting $tar_name"
        echo "$tarCommand"
        exit
      else
        echo "$tarCommand"
        echo "Files have been extracted successfully"
        deleteTarFile=`ssh $staging rm /home/ubuntu/mongodump/dump/backup/$tar_name`
        fileName="${tar_name%%.*}"
        mongo_restore $dumpAll $staging $fileName
      fi
    fi
    exit
  fi
}

help_function()
{
  echo "type ./mongorestore.sh [database_name] [staging_target] to restore a single database"
  echo "type ./mongorestore.sh [staging_target] to restore all mongo databases"
}

restore_single_mongo()
{
  DIR=$1
  if [[ `ssh staging06 test -d $BACKUP_DIR/$DIR/ && echo exists` ]]; then
    echo ".....zipping $1 at staging06....."
 
    command=`ssh staging06 tar -czf $BACKUP_DIR/$1.tar.gz $BACKUP_DIR/$DIR/`
    if [ $? -ne 0 ]; then
      echo "Errors occur, check log at /var/traveloka/log/mongorestore_script.log"
      echo  "$command" >> $LOG_FILE
      exit
    else
      echo "tar complete, copying file to $2"
      echo "................................"
      tar_name="${1}.tar.gz"
      dumpAll=false
      staging=$2
      copy_and_extract_db $dumpAll $tar_name $staging
      exit
    fi
  else
    echo "$1 does not exist"
    exit
  fi
}

restore_all_by_default()
{
  echo "archieving all dumped databases..."
  command=`ssh staging06 tar -czf /home/ubuntu/mongodump/dump/mongodump-all-staging06.tar.gz /home/ubuntu/mongodump/dump/backup/`
  if [ $? -ne 0 ]; then
    echo "Errors occur, check log at /var/traveloka/log/mongorestore_script.log"
    echo  "$command" >> $LOG_FILE
    exit
  else
    echo "all databases have been archieved, copying zipped file to $1"
    echo "..............................."
    tar_name="mongodump-all-staging06.tar.gz"
    dumpAll=true
    staging=$1
    copy_and_extract_db $dumpAll $tar_name $staging
    exit
  fi
}


#THIS IS THE MAIN FUNCTION

case $# in
   0) help_function ;;
   1) restore_all_by_default $1 ;;
   2) restore_single_mongo $1 $2 ;;
esac
