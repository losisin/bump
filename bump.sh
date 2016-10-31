#!/bin/bash

# Bump CLI is a command line backup and restore utility with predefined retention policy
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Unofficial Bash Strict Mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

# Load configuration file
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/default.conf

# Set vars
VERSION="1.0.1"
HOST=$(uname -n)
BAK=false
RST=false
LOCAL=true
REMOTE=false
FREQ="day"
DIR_ARR=("day" "week" "month" "year")

# Ensure bump is run as privileged user
if [[ $(id -u) != 0 ]]; then
  echo "You must be root to run Bump CLI" 1>&2
  exit 1
fi

# Display help page
function usage() {

cat <<EOF
Usage: bump [options]

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
EOF

}

# Prepare command for remote SSH access
function remote_login() {
  if [[ -z "$REMOTE_PASS" ]]; then
    ssh -o "StrictHostKeyChecking no" $REMOTE_USER@$REMOTE_HOST $1
  else
    sshpass -p $REMOTE_PASS ssh -o "StrictHostKeyChecking no" $REMOTE_USER@$REMOTE_HOST $1
  fi
}

# Prepare for parsing options
ARGS="$(getopt -o hBRt:d:f:k:v -l help,backup,restore,type:,destination:,frequency:,keep-files:,version -- "$@")"

# Check response for errors. If that's the case, then exit
if [ $? != 0 ]; then
  echo "Error: Failed parsing options!" >&2
  exit 1
fi

# Iterate over all options
eval set -- "$ARGS"
while true ; do
  case "$1" in
    -h|--help)
      usage
      exit 1
      ;;
    -B|--backup)
      BAK=true
      shift
      ;;
    -R|--restore)
      RST=true
      shift
      ;;
    -t|--type)
      if [[ $2 == "archive" ]]; then
        CMD="tar"
      else
        echo "Error: Parameter for option --type is missing or misspelled!"
        echo "Check your command for missing options or typos."
        exit 2
      fi
      shift 2
      ;;
    -d|--destination)
      if [[ $2 == "remote" ]]; then
        LOCAL=false
        REMOTE=true
      else
        echo "Error: Parameter for --destination is missing or misspelled!"
        echo "Check your command for missing options or typos."
        exit 2
      fi
      shift 2
      ;;
    -f|--frequency)
      if [[ " ${DIR_ARR[*]} " == *" $2 "* ]]; then
        FREQ="$2"
      else
        echo "Error: Parameter for option --frequency is missing or misspelled!"
        echo "Check your command for missing options or typos."
        exit 2
      fi
      shift 2
      ;;
    -k|--keep-files)
      if [[ $2 =~ ^-?[0-9]+$ && $2 -gt 0 ]]; then
        MAX_KEEP=$2
      else
        echo "Error: Parameter for option --keep-files is missing or misspelled!"
        echo "Check your command for missing options or typos."
        exit 2
      fi
      shift 2
      ;;
    -v|--version)
      echo "Bump CLI $VERSION"
      exit
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Invalid option: $1"
      echo "Try running with --help option for instructions."
      exit 1
      ;;
  esac
done

# Don't do anything unless explicitly told
if [[ $BAK == true && $RST == true ]] || [[ $BAK != true && $RST != true ]]; then
    echo "You must choose either backup (-B|--backup) OR restore (-R|--restore)"
    exit
fi

# Load procedure scripts based on user input
if [[ $RST == true ]]; then
  echo "Preparing to restore data."
  echo "Warning: this is potentially dangerous operation. Backup your data first."
  echo "MAKE SURE YOU KNOW WHAT YOU'RE DOING!"
  while true; do
      read -p "Do you sure you want to perform restore? (y/n): " yn
      case $yn in
          [Yy]* ) source $DIR/restore.sh ; break;;
          [Nn]* ) echo "Restore procedure canceled" ; exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
else
  echo "Preparing to backup data. Please wait..."
  source $DIR/backup.sh
fi

exit 0
