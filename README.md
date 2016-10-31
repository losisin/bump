# bump
Bump CLI is a command line backup utility writen in pure bash. You can create backups locally (on  different partition or hard drive) and on remote backup server or storage device as long as you have SSH access. Bump CLi runs agent less, so when backing up local machine on remote host all commands are exceuted over SSH.
## Licence
GPLv3 
## Preruquisites
Bash 4+
sshpass (optional)
## Options
```
Usage: path/to/bump/bump.sh [options] [arguments]

Options:
-h, --help            Print this help message
-B, --backup          Backup file sysytem
-R, --restore         Restore file sysytem
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
## Usage
Bump CLI is meant to be run as root user or with sudo in a cron job. 
Basic usage `/path/to/bump/bump.sh -B`. This will create incremental backup on different partion or hard drive with unlimeted number of backups. You can also choose different options based on your retention policy for backups. Example cron jobs can looks like this:
* Daily incremental backup on different partion or hard drive with unlimeted number of backups using rsync.
```
0 2 * * * /path/to/bump/bump.sh -B >/dev/null 2>&1
```
* Weekly backup on remote host using tarball and keep only last 4 backups (including md5sum files)
30 0 * * 7 /path/to/bump/bump.sh -B -d remote -t archive -f week -k 4 >/dev/null 2>&1

```
## To Do
* Introduce restore procedures
* Optimize network transfer for backup
* Introduce traps and better exit messages
* Introduce logging and logrotate configuration file
* Verify tarball archives as digital archive maintenance
For issues and features request use [GitHUb issues](https://github.com/losisin/bump/issues)
