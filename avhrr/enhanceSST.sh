#!/bin/bash

source /etc/profile.d/netcdf.sh

# Enhances a single SST output file with metadata
# First parameter to the script is the location of the SST
# NetCDF file to enhance.
#
# Filenames are like so:
# 20110801.213.1350.n16.EC1.nc

title="SST"
summary="SST Data"
keywords="MARACOOS, SST, UDEL, Satellite SST, Rutgers, Sea Surface Temperature"
naming_authority="MARACOOS"
id="udel.sst"
cdm_data_type="Grid"
creator_name="Matt Oliver"
creator_url="http://orb.ceoe.udel.edu/"
creator_email="moliver@udel.edu"
standard_name_vocabulary="http://www.cgd.ucar.edu/cms/eaton/cf-metadata/standard_name.html"

echo "Starting enhancement of $1"

# Enhance global attribute metadata
ncatted -h -a title,global,o,c,"$title" $1
ncatted -h -a summary,global,o,c,"$summary" $1
ncatted -h -a keywords,global,o,c,"$keywords" $1
ncatted -h -a naming_authority,global,o,c,"$naming_authority" $1
ncatted -h -a id,global,o,c,"$id" $1
ncatted -h -a cdm_data_type,global,o,c,"$cdm_data_type" $1
ncatted -h -a creator_name,global,o,c,"$creator_name" $1
ncatted -h -a creator_url,global,o,c,"$creator_url" $1
ncatted -h -a creator_email,global,o,c,"$creator_email" $1
ncatted -h -a standard_name_vocabulary,global,o,c,"$standard_name_vocabulary" $1

# Remove the missing value attributes and recreate them as floats
ncatted -h -a _FillValue,mcsst,d,, $1
ncatted -h -a missing_value,mcsst,o,f,-999 $1
ncrename -h -a mcsst@missing_value,_FillValue $1
ncatted -h -a missing_value,mcsst,o,f,-999 $1

# Update CF convention to 1.6
ncatted -h -a Conventions,global,d,, $1
ncatted -h -a Conventions,global,o,c,"CF-1.6" $1
ncatted -h -a Metadata_Conventions,global,o,c,"Unidata Dataset Discovery v1.0" $1

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

# Now combine our file withe the projection file
ncks -h -A crs.nc $1

# Rename all 'documentation' attribute to 'comments'
ncrename -h -a .documentation,comments $1

# Add atttributes to the "crs" variable
ncatted -h -a grid_mapping_name,crs,o,c,"mercator" $1
ncatted -h -a longitude_of_projection_origin,crs,o,d,-75 $1
ncatted -h -a standard_parallel,crs,o,d,37.6960626707359 $1
ncatted -h -a semi_major_axis,crs,o,d,6378137.0 $1
ncatted -h -a inverse_flattening,crs,o,d,0.0 $1

# Add "crs" attribute to the "mcsst" variable
ncatted -h -a grid_mapping,mcsst,o,c,"crs" $1
# Remove unneeded attributes on the "mcsst" variable
ncatted -h -a Equator_Radius,mcsst,d,, $1
ncatted -h -a Projection,mcsst,d,, $1
ncatted -h -a Center_Latitude,mcsst,d,, $1
ncatted -h -a Center_Longitude,mcsst,d,, $1
ncatted -h -a Flattening,mcsst,d,, $1
ncatted -h -a comments,mcsst,o,c,"Projection information found in the crs variable" $1

# Add standard names
ncatted -h -a standard_name,lon,o,c,"longitude" $1
ncatted -h -a standard_name,lat,o,c,"latitude" $1
ncatted -h -a standard_name,time,o,c,"time" $1
ncatted -h -a standard_name,mcsst,o,c,"sea_surface_temperature" $1


echo "Complete."
