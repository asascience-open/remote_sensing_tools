#!/bin/bash

source /etc/profile.d/netcdf.sh

# Enhances a single SST output file with metadata
# First parameter to the script is the location of the SST
# NetCDF file to enhance.
#
# Filenames are like so:
# 4326_201206250700.nc4

title="MODIS Lake Surface Temperature for GLOS (Great Lakes Observing System)"
summary="Lake surface temperature over the Great Lakes and surrounding waters from MODIS satellites."
keywords="GLOS, MODIS, LST, SST, MTRI, AOC, Satellite, Sea Surface Temperature, Lake Surface Temperature"
institution="Michigan Tech Research Institute (MTRI)"
naming_authority="GLOS"
zsource="MODIS Aqua, 4 micrometer night time collection"
id="modis.sst"
cdm_data_type="Grid"
creator_name="Colin Brooks"
creator_url="http://www.mtri.org/"
creator_email="cnbrooks@mtu.edu"
standard_name_vocabulary="http://www.cgd.ucar.edu/cms/eaton/cf-metadata/standard_name.html"
comment="These data are provided to the Great Lakes Observing System from the Michigan Tech Research Institute (MTRI) in Ann Arbor, MI.  For further information about MTRI or these data, please contact Mr. Colin Brooks cnbrooks@mtu.edu"
project="GLOS MTRI AOC"
publisher_name="GLOS DMAC"
publisher_url="http://glos.us"
publisher_email="dmac@glos.us"
metadata_link="http://data.glos.us/portal/"


echo "Starting enhancement of $1"

## GLOBAL LEVEL

# Enhance global attribute metadata
ncatted -h \
  -a title,global,o,c,"$title" \
  -a summary,global,o,c,"$summary" \
  -a keywords,global,o,c,"$keywords" \
  -a institution,global,o,c,"$institution" \
  -a naming_authority,global,o,c,"$naming_authority" \
  -a source,global,o,c,"$zsource" \
  -a id,global,o,c,"$id" \
  -a cdm_data_type,global,o,c,"$cdm_data_type" \
  -a creator_name,global,o,c,"$creator_name" \
  -a creator_url,global,o,c,"$creator_url" \
  -a creator_email,global,o,c,"$creator_email" \
  -a standard_name_vocabulary,global,o,c,"$standard_name_vocabulary" \
  -a comment,global,o,c,"$comment" \
  -a project,global,o,c,"$project" \
  -a publisher_name,global,o,c,"$publisher_name" \
  -a publisher_email,global,o,c,"$publisher_email" \
  -a publisher_url,global,o,c,"$publisher_url" \
  -a metadata_link,global,o,c,"$metadata_link" \
  -a geospatial_vertical_min,global,o,d,0.0 \
  -a geospatial_vertical_max,global,o,d,0.0 \
  -a geospatial_vertical_units,global,o,c,"meters" \
  -a geospatial_vertical_resolution,global,o,d,0.0 \
  -a geospatial_vertical_positive,global,o,c,"up" \
  $1

# Update CF convention to 1.6
ncatted -h \
  -a Conventions,global,d,, \
  -a Conventions,global,o,c,"CF-1.6" \
  -a Metadata_Conventions,global,o,c,"Unidata Dataset Discovery v1.0" \
  $1

## VARIABLE LEVEL

# Remove the missing_value attributes and recreate them as -999.0 (double)
fillvalue=-999.0
ncatted -h -a _FillValue,sst,o,d,$fillvalue $1
ncatted -h -a missing_value,sst,o,d,$fillvalue $1

# Add a variable that represents the time
cat > time.cdl << EOF
  netcdf foo { 
    dimensions:
      time = UNLIMITED;
    variables:
      int time(time);
    data:
      time = -1;
  }
EOF

# Now create a NetCDF with just the time
ncgen -o time.nc time.cdl

# Now combine SST file with the time file
ncks -h -A time.nc $1

# Remove the temporary time files
rm -f time.nc time.cdl

# Strip time from filename
datestring=$(echo $1 | sed 's/\([0-9]\{4\}\)\_\([0-9]\{8\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\.nc4/\2\ \3\:\4:00/' | awk -F"/" '{print $NF}')
timestamp=$(date --utc -d "$datestring" +%s)
tmpfile=/tmp/$timestamp.nc

# Rename variable to 'foo'
ncrename -h -O -v sst,foo $1
  
# Copy data and attributes from 'foo' to the new dimensioned 'sst'.  Set the new time as well.
ncap2 -h -O \
  -s "time[time]=$timestamp" \
  -s 'sst[time,lat,lon]=foo' \
  -s 'sst@grid_mapping=foo@grid_mapping' \
  -s 'sst@long_name=foo@long_name' \
  -s 'sst@coordinates=foo@coordinates' \
  -s 'sst@units=foo@units' \
  -s 'sst@standard_name=foo@standard_name' \
  -s 'sst@missing_value=foo@missing_value' \
  $1 $tmpfile

# Set the time attributes
ncatted -h \
  -a units,time,o,c,"seconds since 1970-01-01 00:00:00" \
  -a long_name,time,o,c,"Time" \
  -a standard_name,time,o,c,"time" \
  $tmpfile

# Fix missing values (can't copy _FillValue attribute with ncap2)
ncrename -O -h -a sst@missing_value,_FillValue $tmpfile
ncatted -O -h -a missing_value,sst,o,d,$fillvalue $tmpfile

# Add comment about projection to the "sst" variable
ncatted -h \
  -a comments,sst,o,c,"Projection information found in the crs variable" \
  $tmpfile

# Remove foo variable and compress the file again to get the new SST variable
ncks -4 -L 3 -h -O -x -v foo $tmpfile $1

rm -f $tmpfile

echo "Complete."
