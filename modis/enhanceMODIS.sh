#!/bin/bash

source /etc/profile.d/netcdf.sh

# Enhances a single MODIS output file with metadata
# First parameter to the script is the location of the MODIS
# NetCDF file to enhance.
#
# Filenames are like so:
# aqua.2012066.0306.170828.D.L3.modis.NAT.v09.1000m.nc4

title="MODIS"
summary="MODIS Data"
keywords="MARACOOS, MODIS, UDEL, Satellite, Rutgers, Chlorophyll"
naming_authority="MARACOOS"
id="udel.modis"
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

# Update CF convention to 1.6 and add UDD attribute
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
# Now create a NetCDF with just the projection
ncgen -b -k 3 -o crs.nc crs.cdl

# Now combine our file withe the projection file
ncks -h -A crs.nc $1

# Remove the crs files
rm -f crs.nc crs.cdl

# Add atttributes to the "crs" variable
ncatted -h \
  -a grid_mapping_name,crs,o,c,"mercator" \
  -a longitude_of_projection_origin,crs,o,c,"TODO" \
  -a standard_parallel,crs,o,c,"TODO" \
  -a semi_major_axis,crs,o,d,6378137.0 \
  -a inverse_flattening,crs,o,d,0.0 \
  $1

# Add "crs" attribute to all the variables, then remove the unneeded ones
ncatted -h -a grid_mapping,,o,c,"crs" $1
ncatted -h \
  -a grid_mapping,lon,d,c,, \
  -a grid_mapping,lat,d,c,, \
  -a grid_mapping,time,d,c,, \
  -a grid_mapping,crs,d,c,, \
  $1

# Add standard names
ncatted -h \
  -a standard_name,lon,o,c,"longitude" \
  -a standard_name,lat,o,c,"latitude" \
  -a standard_name,time,o,c,"time" \
  -a standard_name,chl_oc3,o,c,"chlorophyll_concentration_in_sea_water" \
  -a standard_name,sst,o,c,"sea_surface_temperature" \
  -a standard_name,salinity,o,c,"sea_surface_salinity" \
  -a standard_name,ndvi,o,c,"normalized_difference_vegetation_index" \
  -a standard_name,POM_gould,o,c,"concentration_of_phytoplankton_in_sea_water" \
  -a standard_name,PIM_gould,o,c,"concentration_of_sediment_in_sea_water" \
  -a standard_name,TSS_gould,o,c,"concentration_of_suspended_matter_in_sea_water" \
  -a standard_name,M_WK,o,c,"sea_water_mass_classification" \
  -a standard_name,M_WK_G,o,c,"gradient_strengths_across_sea_water_mass_classification" \
  $1

echo "Complete."
