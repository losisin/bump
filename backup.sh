#!/bin/bash

TODAY=$(date +'%Y%m%d')
TMP_DIR="$BAK_DIR/.tmp"

# Prepare directory array
function prep_dir() {
  if [ ! -d $1 ]; then
    mkdir -p $1
  fi
}

# Clean up temporary directory before we exit
function clean_up() {
  echo "Cleaning up temporary directory and exiting."
  rm -rf $TMP_DIR/*
}

# Retention policy for backup archives
function rotate() {
  if [[ $3 -gt 0 ]]; then
    MAX_KEEP=$3

    # For tar archive mutiple by 2 because of *.md5 files
    if [[ $1 == "tar" ]]; then
      MAX_KEEP=$(( $MAX_KEEP*2 ))
    fi

    echo "Rotate archives by $MAX_KEEP"

    pushd $2
    ls -t | sed -e "1,${MAX_KEEP}d" | xargs rm -rf
    popd
  fi
}

function backup() {
  exclude=""
  if [[ $CMD == "tar" ]]; then

    # Exclude files and directories from list
    if [[ $EXCLUDES == true ]]; then
      exclude="-X $DIR/excludes.txt"
    fi

    # Create temporary directory if it doesn't exists
    if [[ ! -d $TMP_DIR ]]; then
      mkdir -p $TMP_DIR
    fi

    pushd $TMP_DIR

    # Create tar archive in temporary directory
    tar zcfp $TODAY.tar.gz $HOST_DIR $exclude

    # Generate md5sum for archive
    echo "Generating md5sum for archive.."
    md5sum $TODAY.tar.gz > $TODAY.md5

    popd

    # Store backup in appropriate location
    if [[ $LOCAL == true ]]; then

      # Prevent "cp -i" alias on some systems
      /bin/cp -rf $TMP_DIR/$TODAY* $BAK_DIR/$HOST/$FREQ/
    else
      if [[ -z "$REMOTE_PASS" ]]; then
        scp $TMP_DIR/$TODAY* $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$HOST/$FREQ/
      else
        sshpass -p $REMOTE_PASS scp $TMP_DIR/$TODAY* $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$HOST/$FREQ/
      fi
    fi

    clean_up

  else
    # Exclude files and directories from list
    if [[ $EXCLUDES == true ]]; then
      exclude="--exclude-from=$DIR/excludes.txt"
    fi

    if [[ $LOCAL == true ]]; then
      rsync -aAXz $exclude --delete $HOST_DIR $BAK_DIR/$HOST/$FREQ/$TODAY/
    else
      if [[ -z "$REMOTE_PASS" ]]; then
        rsync -aAXz $exclude --delete $HOST_DIR $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$HOST/$FREQ/$TODAY/
      else
        sshpass -p $REMOTE_PASS rsync -aAXz $exclude --delete $HOST_DIR $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$HOST/$FREQ/$TODAY/
      fi
    fi
  fi
}

if [[ $LOCAL == true ]]; then

  # Test directory structure and create it if it's missing
  echo "Checking directory structure..."
  prep_dir $BAK_DIR/$HOST/$FREQ

  # Perform backup operations
  echo "Creating backup..."
  backup

  # Rotate backup archives
  echo "Rotate backup archives..."
  rotate $CMD $BAK_DIR/$HOST/$FREQ/ $MAX_KEEP
else

  # Test directory structure and create it if it's missing
  echo "Connecting to remote host..."
  remote_login "$(declare -f prep_dir); prep_dir $REMOTE_DIR/$HOST/$FREQ"

  # Perform backup operations
  echo "Creating backup..."
  backup

  # Rotate backup archives
  echo "Rotate backup archives..."
  remote_login "$(declare -f rotate); rotate $CMD $REMOTE_DIR/$HOST/$FREQ $MAX_KEEP"
fi

echo "Done"
