#!/bin/bash

source /etc/profile.d/netcdf.sh

d1=$(date '+%s')

# Composite days are the first paramter into the script
# Location of RAW output is second
# Where to save fixed output is third
# Folder to put composite in is fourth

files=""
justDates=""
numDays=$1
echo "Starting masking..."
for f in `find $2 -mtime -${numDays} -type f`; do
  # 20110801.213.1350.n16.EC1.nc
  fileDt=$(echo $f | sed 's/\([0-9]\{8\}\)\.\([0-9]\{3\}\)\.\([0-9]\{2\}\)\([0-9]\{2\}\)\.n\([0-9]\{2\}\)\.EC1\.nc/\1\ \3\:\4:00/' | awk -F"/" '{print $NF}')
  d2=$(date --utc -d "$fileDt" +%s)
  diff=$((d1-d2))
  seconds=$((numDays * 24 * 60 * 60))
  if [ $diff -lt $seconds ]; then

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
      # Do some cleanup on the MissingValue attributes files
      ncatted -h -a _FillValue,mcsst,d,, $f $outPath
      ncrename -h -a mcsst@missing_value,_FillValue $outPath
      ncatted -h -a missing_value,mcsst,o,f,-999 $outPath
 
      # Mask the SST
      ncwa -4 -L 9 -h -y avg -a time -b -v mcsst -m cloud_land_mask -B "cloud_land_mask = 0" $outPath $finalPath
      rm $outPath
    fi
    files=${files}" "${finalPath}
    justDates=${justDates}" "${outFile}
  fi
done
echo "Complete."
echo "Starting composite..."
# Sort the dates
reverseFiles=$(echo $files | sed 's/ /\n/g' | sort -r | sed 's/\n/ /g')
files=$(echo $files | sed 's/ /\n/g' | sort | sed 's/\n/ /g')
lastFile=$(echo ${files##*/} | sed 's/\([0-9]\{8\}\)\.\([0-9]\{3\}\)\.\([0-9]\{2\}\)\([0-9]\{2\}\)\.n\([0-9]\{2\}\)\.EC1\.masked\.nc/\1\ \3\:\4:00/' | awk -F"/" '{print $NF}')
lastDate=$(date --utc -d "$lastFile" +%Y-%m-%dT%H:%M:%SZ)
lastFileDate=$(date --utc -d "$lastFile" +%Y%m%d.%H%M)
lastFileYear=$(date --utc -d "$lastFile" +%Y)
lastFileMonth=$(date --utc -d "$lastFile" +%m)
compositeDirectory=$4/$lastFileYear/$lastFileMonth

if [ ! -z "$files" ]; then
  if [ ! -d "$compositeDirectory" ]; then
    mkdir -p $compositeDirectory
  fi 
  compFile=$compositeDirectory/${lastFileDate}.d${numDays}.composite.nc4
  if [ ! -f "$compFile" ]; then
    echo "Making ${numDays}-day composite from ${lastDate}..."
    tmpdir="temp"
    mkdir $tmpdir
    ncea -4 -L 9 -h -y avg -v chl_oc3 $reverseFiles $tmpdir/chl.nc4
    ncea -4 -L 9 -h -y avg -v sst $reverseFiles $tmpdir/sst.nc4
    ncea -4 -L 9 -h -y avg -v ndvi $reverseFiles $tmpdir/ndvi.nc4
    ncea -4 -L 9 -h -y avg -v salinity $reverseFiles $tmpdir/sal.nc4
    ncea -4 -L 9 -h -y avg -v M_WK $reverseFiles $tmpdir/MWK.nc4 # seems to cause issues
    ncea -4 -L 9 -h -y avg -v M_WK_G $reverseFiles $tmpdir/MWKG.nc4
    ncea -4 -L 9 -h -y avg -v PIM_gould $reverseFiles $tmpdir/PIM.nc4
    ncea -4 -L 9 -h -y avg -v POM_gould $reverseFiles $tmpdir/POM.nc4
    ncea -4 -L 9 -h -y avg -v TSS_gould $reverseFiles $tmpdir/TSS.nc4
    echo "Saving to $compFile..."
    ncks $tmpdir/chl.nc4 $compFile
    ncks -A $tmpdir/sst.nc4 $compFile
    ncks -A $tmpdir/ndvi.nc4 $compFile
    ncks -A $tmpdir/sal.nc4 $compFile
    ncks -A $tmpdir/MWK.nc4 $compFile
    ncks -A $tmpdir/MWKG.nc4 $compFile
    ncks -A $tmpdir/PIM.nc4 $compFile
    ncks -A $tmpdir/POM.nc4 $compFile
    ncks -A $tmpdir/TSS.nc4 $compFile
    rm -rf $tmpdir
    ncatted -h -a history,global,d,, $compFile
    ncatted -h -a composite_members,global,o,c,"$justDates" $compFile
  else
    echo "Composite file already exists: $compFile"
  fi
else
  echo "No files to composite!"
fi