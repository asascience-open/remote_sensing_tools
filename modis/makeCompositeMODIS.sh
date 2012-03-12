#!/bin/bash

source /etc/profile.d/netcdf.sh

d1=$(date '+%s')

# Composite days are the first paramter into the script
# Location of RAW output is second
# Folder to put composite in is third

files=""
justDates=""
numDays=$1
echo "Starting composite..."
for f in `find $2 -mtime -${numDays} -type f`; do
  # aqua.2012066.0306.170828.D.L3.modis.NAT.v09.1000m.nc4
  fileDt=$(echo $f | sed 's/aqua\.\([0-9]\{4\}\)\([0-9]\{3\}\)\.\([0-9]\{4\}\)\.\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\.D\.L3\.modis\.NAT\.v09\.1000m\.nc4/\1\3\ \4\:\5\:\6/' | awk -F"/" '{print $NF}')
  d2=$(date --utc -d "$fileDt" +%s)
  diff=$((d1-d2))
  seconds=$((numDays * 24 * 60 * 60))
  if [ $diff -lt $seconds ]; then
    tmp=${f##*/}
    outFile=${tmp%.*}
    files=${files}" "${f}
    justDates=${justDates}" "${outFile}
  fi
done

# Sort the dates
reverseFiles=$(echo $files | sed 's/ /\n/g' | sort -r | sed 's/\n/ /g')
files=$(echo $files | sed 's/ /\n/g' | sort | sed 's/\n/ /g')
lastFile=$(echo ${files##*/} | sed 's/aqua\.\([0-9]\{4\}\)\([0-9]\{3\}\)\.\([0-9]\{4\}\)\.\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\.D\.L3\.modis\.NAT\.v09\.1000m\.nc4/\1\3\ \4\:\5\:\6/' | awk -F"/" '{print $NF}')
lastDate=$(date --utc -d "$lastFile" +%Y-%m-%dT%H:%M:%SZ)
lastFileDate=$(date --utc -d "$lastFile" +%Y%m%d.%H%M%S)
lastFileYear=$(date --utc -d "$lastFile" +%Y)
lastFileMonth=$(date --utc -d "$lastFile" +%m)
compositeDirectory=$3/$lastFileYear/$lastFileMonth
productList=('chl_oc3' 'sst' 'ndvi' 'salinity' 'M_WK' 'M_WK_G' 'PIM_gould' 'POM_gould' 'TSS_gould')
productString=$(echo ${productList[*]})
echo $productString

if [ ! -z "$files" ]; then
  if [ ! -d "$compositeDirectory" ]; then
    mkdir -p $compositeDirectory
  fi 
  compFile=$compositeDirectory/${lastFileDate}.d${numDays}.composite.nc
  # Have we already created this composite?
  if [ ! -f "$compFile" ]; then
    echo "Making ${numDays}-day composite from ${lastDate}..."
    # Use a unique directory name as the temp directory.
    # So if the script is run at the same time as another, it does
    # not wipe the same temp directory.
    tmpdir="temp${RANDOM}"
    mkdir $tmpdir

    # Composite each product seperately
    # Use the first index as a base file to add the other
    # composite variables to
    for index in ${!productList[*]}
    do
      echo "Compositing: ${productList[${index}]}"
      ncea -4 -L 9 -h -y avg -v ${productList[${index}]} $reverseFiles ${tmpdir}/${productList[${index}]}.nc
      echo "Appending ${productList[${index}]} to output"
      if [ "0" -ne "$index" ]; then
        ncks -A ${tmpdir}/${productList[${index}]}.nc ${tmpdir}/${productList[0]}.nc
      fi
    done

    mv ${tmpdir}/${productList[0]}.nc $compFile
    rm -rf $tmpdir # removing temp directory

    ncatted -h \
      -a history,global,d,, \
      -a composite_members,global,o,c,"$justDates" \
      -a product_list,global,o,c,"$productString" \
      $compFile
  else
    echo "Composite file already exists: $compFile"
  fi
else
  echo "No files to composite!"
fi