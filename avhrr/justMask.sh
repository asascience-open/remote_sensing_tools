#!/bin/bash

source /etc/profile.d/netcdf.sh

path=`dirname $2`
base=`basename $2`

echo "Starting masking on $base"

# Composite days are the first paramter into the script
# Absolute path to the BASE FILE to go back from is second
# Folder to put masked files in is third
# Folder to put composite in is fourth

numDays=$1
seconds=$((numDays * 24 * 60 * 60))

basefileDt=$(echo $base | sed 's/\([0-9]\{8\}\)\.\([0-9]\{3\}\)\.\([0-9]\{2\}\)\([0-9]\{2\}\)\.n\([0-9]\{2\}\)\.EC1\.nc/\1\ \3\:\4:00/' | awk -F"/" '{print $NF}')
baseD=$(date --utc -d "$basefileDt" +%s)

for f in `find $path -type f`; do
  # 20110801.213.1350.n16.EC1.nc
  fileDt=$(echo $f | sed 's/\([0-9]\{8\}\)\.\([0-9]\{3\}\)\.\([0-9]\{2\}\)\([0-9]\{2\}\)\.n\([0-9]\{2\}\)\.EC1\.nc/\1\ \3\:\4:00/' | awk -F"/" '{print $NF}')
  fileD=$(date --utc -d "$fileDt" +%s)
  diff=$((baseD-fileD))
  if [ $diff -ge 0 ]; then
    if [ $diff -le $seconds ]; then
      outDirectory=$3/$(date --utc -d "$fileDt" +%Y)/$(date --utc -d "$fileDt" +%m)
      if [ ! -d "$outDirectory" ]; then
        mkdir -p $outDirectory
      fi
      tmp=${f##*/}
      outFile=${tmp%.*}
      outPath=$outDirectory/$outFile.nc
      finalPath=$outDirectory/$outFile.masked.nc

      # Have we already created the mask for this file?
      if [ ! -f $finalPath ]; then
        echo "Masking to $finalPath..."
        # Do some cleanup on the MissingValue attributes files
        ncatted -h -a _FillValue,mcsst,d,, $f $outPath
        ncatted -h -a missing_value,mcsst,o,f,-999 $outPath
        ncrename -h -a mcsst@missing_value,_FillValue $outPath
        ncatted -h -a missing_value,mcsst,o,f,-999 $outPath

        # Mask the SST
        ncwa -4 -L 9 -h -y avg -a time -b -v mcsst -m cloud_land_mask -B "cloud_land_mask = 0" $outPath $finalPath
        rm $outPath
      fi
    fi
  fi
done