#!/bin/bash -e

ini(){
  if [[ -f $1 ]]; then
    . $1
  fi
  check_variables
}

check_variables(){
  if [[ -z "${PERSISTENCE_DIR}" || -z ${STORE_DIR} || -z ${YML_PATH} || -z ${URL} ]]; then
    print_help
    exit 1
  fi
}

# Wait for server status
wait_until_status(){
  url="$1"
  exp_st="$2"
  SECONDS=0
  waitsec=120
  while :
  do
    res=$(curl -s -o /dev/null -I -w "%{http_code}" $url) || true
    if [ $res == $exp_st ]; then
      echo "Confirmed status $exp_st"
      break
    else
      if [ $SECONDS -gt $waitsec ]; then
        echo "Timeout while waiting for status $exp_st"
        exit 1
      else
        echo "Wait for server status of $exp_st (current:$res)"
      fi
    fi
    sleep 5
    continue
  done
}

stop_container(){
  echo Stop container
  docker-compose -f $YML_PATH stop
  wait_until_status $URL "000"
}

start_container(){
  echo Start container
  docker-compose -f $YML_PATH up -d
  wait_until_status $URL "200"
}

backup(){

  stop_container

  echo Backup persistence dir
  ( \
   cd $PERSISTENCE_DIR/.. && \
   mkdir -p $STORE_DIR && \
   tar cvzfp "$STORE_DIR/$PREF-$(date +%Y%m%d%H%M%S).tar.gz" "$(basename $PERSISTENCE_DIR)" \
  )

  start_container
}

rollback(){

  stop_container

  if [ -d $PERSISTENCE_DIR ]; then
    echo Evacuate current persistence dir
    ( \
     cd $PERSISTENCE_DIR/.. && \
     tar cvzfp "$PREF-evacuate-$(date +%Y%m%d%H%M%S).tar.gz" "$(basename $PERSISTENCE_DIR)" \
    )

    echo Remove docker container
    docker-compose -f $YML_PATH rm -f

    echo Delete current persistence dir
    rm -r $PERSISTENCE_DIR

  else
    echo Persistence dir is not exists. Skip Evacuation.
  fi

  mkdir -p $PERSISTENCE_DIR

  [ -z "$ROLLBACK_PATH" ] && ROLLBACK_PATH=$(find $STORE_DIR/$PREF-*.tar.gz | sort -r | head -n 1)
  echo Rollback persistence dir from $ROLLBACK_PATH
  (cd $PERSISTENCE_DIR/.. && tar xvzfp $ROLLBACK_PATH)

  start_container

}

print_help(){
  cat << EOS
# BackupTool
Tool to backup and rolleback Docker container data storage.

## Prerequisites
 [curl](https://curl.haxx.se/)
 [docker-compose](https://github.com/docker/compose)

## Usage
 sudo $0 COMMAND [OPTIONS]
 * The reason to use sudo is that the operation of Docker requires the privileges of root user

Command:
  backup          :Backup container data storage. Stop and restart server before and after backup operation.
  rollback        :Rollback container data storage. Use latest backup file by default. You can specify the backup file by --file option.
  help            :Print this message

Options:
  -f --file FILE  :Specify the backup file to be rollbacked.
  -c --config FILE:Please see Clonfig section for more details.

1. Use a configration file:
 sudo $0 /path/to/the/config/file.conf backup

2. Use Environment variable:
 export PERSISTENCE_DIR=...
 export STORE_DIR=...
 export YML_PATH=...
 export URL=...
 sudo $0 backup

## Config
 PROJECT_DIR : Project directory (Required)
 PERSISTENCE_DIR : Persistence directory (Required)
 STORE_DIR : Store directory (Required)
 YML_PATH : Path to docker-compose.yml (Required)
 PREF : Backup file prefix (Option:Nothing is set by default)
 URL : Server URL (Required)
EOS
}

while [[ $# -ge 1 ]]
do
  key="$1"

  case $key in
    backup)
      COMMAND="$1"
      ;;
    rollback)
      COMMAND="$1"
      ;;
    -f|--file)
      ROLLBACK_PATH="$2"
      shift
      ;;
    -c|--config)
      CONF="$2"
      shift
      ;;
    *)
      ;;
  esac
  shift
done

ini ${CONF}

if [[ -z $COMMAND ]]; then
  print_help
  exit 1
fi

if [[ $COMMAND == "backup" ]]; then
  backup
else
  rollback
fi

exit 0
