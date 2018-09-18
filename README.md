# BackupTool
Tool to backup and rolleback Docker container data storage.

## Prerequisites
 [curl](https://curl.haxx.se/)  
 [docker-compose](https://github.com/docker/compose)  
  
## Usage
 ```sudo backup.sh COMMAND [OPTIONS]```  
 * The reason to use sudo is that the operation of Docker requires the privileges of root user  
  
Command:  
  backup          :Backup container data storage. Stop and restart server before and after backup operation.  
  rollback        :Rollback container data storage. Use latest backup file by default. You can specify the backup file by --file option.
  help            :Print this message  
  
Options:  
  -f --file FILE  :Specify the backup file to be rollbacked.  
  -c --config FILE:Please see Clonfig section for more details.  
  
1. Use a configration file:  
 ```sudo backup.sh /path/to/the/config/file.conf backup```  
  
2. Use Environment variable:  
 ```export PERSISTENCE_DIR=...  
 export STORE_DIR=...  
 export YML_PATH=...  
 export URL=...  
 sudo backup.sh backup```  
  
## Config
 PROJECT_DIR : Project directory (Required)  
 PERSISTENCE_DIR : Persistence directory (Required)  
 STORE_DIR : Store directory (Required)  
 YML_PATH : Path to docker-compose.yml (Required)  
 PREF : Backup file prefix (Option:Nothing is set by default)  
 URL : Server URL (Required)  
  
## Authores
 **Kurumi Kurogi** - *initial work* - [kurogi_k](https://scm.hue.workslan/kurogi_k)  
See also the list of [contributors](https://scm.hue.workslan/kurogi_k/backupTool/settings/members) who participated in this project.
