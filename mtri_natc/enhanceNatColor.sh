#!/bin/bash

source /etc/profile.d/netcdf.sh

# Enhances a single Natural Color output file with metadata
# First parameter to the script 
#
# Filenames are like so (YYYYMMDD_HHMM.nc4)
# 20120321_1625.nc4

# First parameter is the location of the Natural Color NetCDF file to enhance.
# Second parameter is the lake name, capitalized. ie. Erie/Michigan

# NOTE: replace "SATELLITE_TYPE" with the satellite type, ie. MODIS / AVHRR
# NOTE: update the "zsource" variable, ie. "MODIS Aqua, 4 micrometer night time collection"

title="Lake $2 - SATELLITE_TYPE - Naturual Color Imagery"
summary="Natural Color Imagery for the Lake $2 and surrounding water from SATELLITE_TYPE satellites"
keywords="GLOS, SATELLITE_TYPE, MTRI, Natural Color Imagery, Basemap, Satellite"
institution="Michigan Tech Research Institute (MTRI)"
naming_authority="GLOS"
zsource="SOURCE"
id="SATELLITE_TYPE.nci"
cdm_data_type="Grid"
creator_name="Colin Brooks"
creator_url="http://www.mtri.org/"
creator_email="cnbrooks@mtu.edu"
standard_name_vocabulary="http://www.cgd.ucar.edu/cms/eaton/cf-metadata/standard_name.html"
comment="These data are provided to the Great Lakes Observing System from the Michigan Tech Research Institute (MTRI) in Ann Arbor, MI.  For further information about MTRI or these data, please contact Mr. Colin Brooks cnbrooks@mtu.edu"
project="GLOS MTRI"
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

# Add standard_names to the Band variables
ncatted -h \
  -a standard_name,Band1,o,c,"red_spectral_band" \
  -a standard_name,Band2,o,c,"green_spectral_band" \
  -a standard_name,Band3,o,c,"blue_spectral_band" \
  $1

# Remove the missing_value attributes and recreate them as -999.0 (byte)
fillvalue=0

ncatted -h \
  -a _FillValue,Band1,o,b,$fillvalue \
  -a _FillValue,Band2,o,b,$fillvalue \
  -a _FillValue,Band3,o,b,$fillvalue \
  $1

ncatted -h \
  -a missing_value,Band1,o,b,$fillvalue \
  -a missing_value,Band2,o,b,$fillvalue \
  -a missing_value,Band3,o,b,$fillvalue \
  $1

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

# Now combine data file file with the time file
ncks -h -A time.nc $1

# Remove the temporary time files
rm -f time.nc time.cdl

# Strip time from filename format "20120321_1625.nc4"
datestring=$(echo $1 | sed 's/\([0-9]\{8\}\)\_\([0-9]\{2\}\)\([0-9]\{2\}\)\.nc[4]\?/\1\ \2\:\3\:00/'  | awk -F"/" '{print $NF}')
timestamp=$(date --utc -d "$datestring" +%s)
tmpfile=/tmp/$timestamp.nc

# Rename 'Band1-3' variables to 'foo1-3'
ncrename -h -O -v Band1,foo1 $1
ncrename -h -O -v Band2,foo2 $1
ncrename -h -O -v Band3,foo3 $1
  
# Copy data and attributes from 'foo1-3' to the new dimensioned 'Band1-3'.  Set the new time as well.
ncap2 -h -O \
  -s "time[time]=$timestamp" \
  -s 'Band1[time,lat,lon]=foo1' \
  -s 'Band1@grid_mapping=foo1@grid_mapping' \
  -s 'Band1@long_name=foo1@long_name' \
  -s 'Band1@coordinates=foo1@coordinates' \
  -s 'Band1@standard_name=foo1@standard_name' \
  -s 'Band1@missing_value=foo1@missing_value' \
  -s 'Band2[time,lat,lon]=foo2' \
  -s 'Band2@grid_mapping=foo2@grid_mapping' \
  -s 'Band2@long_name=foo2@long_name' \
  -s 'Band2@coordinates=foo2@coordinates' \
  -s 'Band2@standard_name=foo2@standard_name' \
  -s 'Band2@missing_value=foo2@missing_value' \
  -s 'Band3[time,lat,lon]=foo3' \
  -s 'Band3@grid_mapping=foo3@grid_mapping' \
  -s 'Band3@long_name=foo3@long_name' \
  -s 'Band3@coordinates=foo3@coordinates' \
  -s 'Band3@standard_name=foo3@standard_name' \
  -s 'Band3@missing_value=foo3@missing_value' \
  $1 $tmpfile

# Set the time attributes
ncatted -h \
  -a units,time,o,c,"seconds since 1970-01-01 00:00:00" \
  -a long_name,time,o,c,"Time" \
  -a standard_name,time,o,c,"time" \
  $tmpfile

# Fix missing values (can't copy _FillValue attribute with ncap2)
ncrename -O -h -a Band1@missing_value,_FillValue $tmpfile
ncrename -O -h -a Band2@missing_value,_FillValue $tmpfile
ncrename -O -h -a Band3@missing_value,_FillValue $tmpfile
ncatted -h \
  -a missing_value,Band1,o,d,$fillvalue \
  -a missing_value,Band2,o,d,$fillvalue \
  -a missing_value,Band3,o,d,$fillvalue \
  $tmpfile

# Add in some units
ncatted -h \
  -a units,Band1,o,c,red_band_intensity \
  -a units,Band2,o,c,green_band_intensity \
  -a units,Band3,o,c,blue_band_intensity \
  $tmpfile

# Add comment about projection to the "Band1-3" variables
ncatted -h \
  -a comments,Band1,o,c,"Projection information found in the crs variable" \
  -a comments,Band2,o,c,"Projection information found in the crs variable" \
  -a comments,Band3,o,c,"Projection information found in the crs variable" \
  $tmpfile

# Remove foo1-3 variable and compress the file again to get the new Band1-3 variables
ncks -4 -L 3 -h -O -x -v foo1,foo2,foo3 $tmpfile $1

rm -f $tmpfile

echo "Complete."
