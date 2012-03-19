#!/bin/bash

source /etc/profile.d/netcdf.sh

# Enhances a single SST output file with metadata
# First parameter to the script is the location of the SST
# NetCDF file to enhance.
#
# Filenames are like so:
# 20110801.213.1350.n16.EC1.nc

title="AVHRR Sea Surface Temperature for MARACOOS (Mid-Atlantic Regional Association Coastal Ocean Observing System)"
summary="Sea surface temperature over the Mid-Atlantic and surrounding waters from NOAA AVHRR satellites. MCSST calculation and image navigation by TeraScan software; Regridded to Mercator lon/lat projection. Processed and De-clouded at University of Delaware. All data data are preserved, and a multi class cloud mask is provided to the user."
keywords="MARACOOS, AVHRR, SST, UDEL, Satellite SST, Rutgers, Sea Surface Temperature"
naming_authority="MARACOOS"
id="avhrr.sst"
cdm_data_type="Grid"
creator_name="Matt Oliver"
creator_url="http://orb.ceoe.udel.edu/"
creator_email="moliver@udel.edu"
standard_name_vocabulary="http://www.cgd.ucar.edu/cms/eaton/cf-metadata/standard_name.html"

echo "Starting enhancement of $1"

# Enhance global attribute metadata
ncatted -h \
  -a title,global,o,c,"$title" \
  -a summary,global,o,c,"$summary" \
  -a keywords,global,o,c,"$keywords" \
  -a naming_authority,global,o,c,"$naming_authority" \
  -a id,global,o,c,"$id" \
  -a cdm_data_type,global,o,c,"$cdm_data_type" \
  -a creator_name,global,o,c,"$creator_name" \
  -a creator_url,global,o,c,"$creator_url" \
  -a creator_email,global,o,c,"$creator_email" \
  -a standard_name_vocabulary,global,o,c,"$standard_name_vocabulary" \
  $1

# Remove the missing value attributes and recreate them as floats
ncatted -h -a _FillValue,mcsst,d,, $1
ncatted -h -a missing_value,mcsst,o,f,-999 $1
ncrename -h -a mcsst@missing_value,_FillValue $1
ncatted -h -a missing_value,mcsst,o,f,-999 $1

# Update CF convention to 1.6
ncatted -h \
  -a Conventions,global,d,, \
  -a Conventions,global,o,c,"CF-1.6" \
  -a Metadata_Conventions,global,o,c,"Unidata Dataset Discovery v1.0" \
  $1

# Add a variable that represents the projection
# Create the projection CDL
cat > crs.cdl << EOF
  netcdf foo { 
  variables:
    int crs;
  }
EOF
# Now create a NetCDF with just the projectino
ncgen -b -k 3 -o crs.nc crs.cdl

# Now combine SST file with the projection file
ncks -h -A crs.nc $1

# Remove the temporary crs files
rm -f crs.nc crs.cdl

# Rename all 'documentation' attribute to 'comments'
ncrename -h -a .documentation,comments $1

# Add atttributes to the "crs" variable
ncatted -h \
  -a grid_mapping_name,crs,o,c,"mercator" \
  -a longitude_of_projection_origin,crs,o,d,-75.0 \
  -a standard_parallel,crs,o,d,37.6960626707359 \
  -a semi_major_axis,crs,o,d,6378137.0 \
  -a inverse_flattening,crs,o,d,0.0 \
  $1

# Add "grid_mapping" attribute to the "mcsst" variable
ncatted -h -a grid_mapping,mcsst,o,c,"crs" $1

# Remove unneeded attributes on the "mcsst" variable
ncatted -h \
	-a Equator_Radius,mcsst,d,, \
	-a Projection,mcsst,d,, \
	-a Center_Latitude,mcsst,d,, \
	-a Center_Longitude,mcsst,d,, \
	-a Flattening,mcsst,d,, \
	-a comments,mcsst,o,c,"Projection information found in the crs variable" \
	$1

# Add standard names
ncatted -h \
	-a standard_name,lon,o,c,"longitude" \
	-a standard_name,lat,o,c,"latitude" \
	-a standard_name,time,o,c,"time" \
	-a standard_name,mcsst,o,c,"sea_surface_temperature" \
	$1

echo "Complete."
