# Bump CLI
Bump CLI is a command line backup utility writen in pure bash. You can create backups locally (on  different partition or hard drive) and on remote backup server or storage device as long as you have SSH access. Bump CLI runs agent less, so when backing up local machine on remote host all commands are exceuted over SSH. Bump CLI currently can perform backup only for files. Database backup such as MySQL, PostgreSQL etc... is not supported.
## Licence
GPLv3
## Version
1.0.2
## Prerequisites
* Bash 4+
* sshpass (optional)

## Features
* Full system backup using tarball or rsync
* Store backup archives locally or remotely (over SSH)
* Predefined retention policy
* Rotation of backup archives
* Backup archives maintenance with checksum verification

## Options
```
Usage: /path/to/bump/bump.sh [options] [arguments]

Options:
-h, --help            Print this help message
-B, --backup          Backup file sysytem
-R, --restore         Restore file sysytem
-V, --verify          Verify checksum for tarball created archives
-t, --type            Type of backup to create.
                      It can be raw hard links using rsync or archive file using tar.
                      Default is raw.
-d, --destination     Destination of backups created. Choose between local or remote.
                      Default is local.
-f, --frequency       Frequency of backups. Bump CLI creates directory structure for:
                      day, week, month and year.
                      Default is day
-k, --keep-files      Number of backups to keep depending on frequency option.
                      Default is -1 (unlimited)
-v, --version         Bump CLI version
```
## Directory structure
```
/path/to/backup/directory
    |__ $HOSTNAME
        |__ day/
        |__ week/
        |__ month/
        |__ year/
```
## Usage
Bump CLI is meant to be run as root user or with sudo privileges in a cron job.
### Backup
Basic usage `/path/to/bump/bump.sh -B`. This will create incremental backup on different partion or hard drive with unlimeted number of backups. You can also choose different options based on your retention policy for backups. Example cron jobs:

Daily incremental backup (at 2:00 AM) on different partition or hard drive with unlimited number of backups using rsync:
```
0 2 * * * /path/to/bump/bump.sh -B >/dev/null 2>&1
```
Weekly backup (every Sunday at 01:30 AM) on remote host using tarball and keep only last 4 backups (including md5sum files):
```
30 1 * * 7 /path/to/bump/bump.sh -B -d remote -t archive -f week -k 4 >/dev/null 2>&1

```
### Verify
Occasionally, we need to make sure our backup archives are in good shape. In oder words, we don't end up with, for ex. corrupted files which will make our backups useless. That's where `-V, --verify` option kicks in. You can set up cron job that will run every few months. Here is an example cron job that will verify backups at 05:00 AM on 1<sup>st</sup> day of month every 6<sup>th</sup> month on remote server:
```
0 5 1 */6 * /path/to/bump/bump.sh -V -d remote
```
**NOTE:** Verify option is only available for backups created with tarball. It doesn't make sense to create checksum for every file if you are using `-t raw` option (done with rsync).
## To Do
* Introduce restore procedures
* Optimize creation and network transfer for backups
* Introduce traps and better exit messages
* Introduce logging and logrotate configuration file
* Make backup archives immutable (read only)

For issues and features request use [GitHUb issues](https://github.com/losisin/bump/issues).
