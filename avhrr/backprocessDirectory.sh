#!/bin/bash

source /etc/profile.d/netcdf.sh

echo "Backprocessing SST masks/composites from $2..."

# Composite days are the first paramter into the script
# Abolute Location of RAW data is second
# Folder to put masked in is third
# Folder to put composite in is fourth

for f in `find $2 -type f`; do
  # 20110801.213.1350.n16.EC1.nc
  fileDt=$(echo $f | sed 's/\([0-9]\{8\}\)\.\([0-9]\{3\}\)\.\([0-9]\{2\}\)\([0-9]\{2\}\)\.n\([0-9]\{2\}\)\.EC1\.nc/\1\ \3\:\4:00/' | awk -F"/" '{print $NF}')
  fileD=$(date --utc -d "$fileDt" +%Y%m%d.%H%M)
  count=`find $4 -type f -name $fileD* | wc -l`
  if [ $count -eq 0 ]; then
    echo "Creating masks/composite for $f"
    # Get working directory
    DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    bash $DIR/makeSSTComposite.sh $1 $f $3 $4
  fi
done