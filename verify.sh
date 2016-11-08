#!/bin/bash

function verify() {

  # Get subdirectories and verify checksum
  for D in $1/*; do
    if [[ -d ${D} ]]; then
      pushd ${D}
      find . -maxdepth 1 -name "*.md5" -type f -exec md5sum -c {} \;
      popd
    fi
  done
}

# Execute verify locally or remote
if [[ $LOCAL == true ]]; then
  verify $BAK_DIR/$HOST
else
  remote_login "$(declare -f verify); verify $REMOTE_DIR/$HOST"
fi

echo "Verifying backup archives done."
