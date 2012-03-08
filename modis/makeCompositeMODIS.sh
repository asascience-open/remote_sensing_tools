#!/bin/bash

source /etc/profile.d/netcdf.sh

d1=$(date '+%s')

# Composite days are the first paramter into the script
# Location of RAW output is second
# Where to save fixed output is third
# Folder to put composite in is fourth

files=""
echo "Starting composite..."
for f in `find $1 -type f`; do
  # aqua.2012066.0306.170828.D.L3.modis.NAT.v09.1000m.nc4
  files=${files}" "${f}
done

tmpdir="temp/"
mkdir $tmpdir

ncea -4 -L 9 -h -y avg -v chl_oc3 $files "$tmpdir/clo.nc"
ncea -4 -L 9 -h -y avg -v sst $files "$tmpdir/sst.nc"
ncea -4 -L 9 -h -y avg -v ndvi $files "$tmpdir/ndvi.nc"
ncea -4 -L 9 -h -y avg -v salinity $files "$tmpdir/salinity.nc"
ncea -4 -L 9 -h -y avg -v M_WK $files "$tmpdir/M_WK.nc"
ncea -4 -L 9 -h -y avg -v M_WK_G $files "$tmpdir/M_WK_G.nc"
ncea -4 -L 9 -h -y avg -v PIM_gould $files "$tmpdir/PIM_gould.nc"
ncea -4 -L 9 -h -y avg -v POM_gould $files "$tmpdir/POM_gould.nc"
ncea -4 -L 9 -h -y avg -v TSS_gould $files "$tmpdir/TSS_gould.nc"

# Now union all of the files in $tmpdir using ncks.
# Don't save the output in $tmpdir, because it is removed.

# Remove the files we don't need anymore.
rm -rf $tmpdir

echo "Complete."