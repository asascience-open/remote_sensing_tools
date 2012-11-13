#!/bin/bash

source /etc/profile.d/netcdf.sh

echo "Backprocessing MODIS composites from in $2..."

# Composite days are the first paramter into the script
# Abolute Location of RAW data is second
# Folder to put composite in is third

for f in `find $2 -type f`; do
  # aqua.2012066.0306.170828.D.L3.modis.NAT.v09.1000m.nc4
  fileDt=$(echo $f | sed 's/aqua\.\([0-9]\{4\}\)\([0-9]\{3\}\)\.\([0-9]\{4\}\)\.\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\.D\.L3\.modis\.NAT\.v09\.1000m\.nc4/\1\3\ \4\:\5\:\6/' | awk -F"/" '{print $NF}')
  fileD=$(date --utc -d "$fileDt" +%Y%m%d.%H%M%S)
  count=`find $3 -type f -name $fileD* | wc -l`
  if [ $count -eq 0 ]; then
    echo "Creating composite for $f"
    # Get working directory
    DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    bash $DIR/makeMODISComposite.sh $1 $f $3
  fi
done