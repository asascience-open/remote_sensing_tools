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
institution="University of Delaware"
naming_authority="MARACOOS"
zsource="NOAA AVHRR"
id="avhrr.sst"
cdm_data_type="Grid"
creator_name="Matt Oliver"
creator_url="http://orb.ceoe.udel.edu/"
creator_email="moliver@udel.edu"
standard_name_vocabulary="http://www.cgd.ucar.edu/cms/eaton/cf-metadata/standard_name.html"
publisher_name="MARACOOS DMAC"
publisher_url="http://maracoos.org"
publisher_email="maracoosinfo@udel.edu"

echo "Starting enhancement of $1"

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
  -a publisher_name,global,o,c,"$publisher_name" \
  -a publisher_email,global,o,c,"$publisher_email" \
  -a publisher_url,global,o,c,"$publisher_url" \
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
  
# enhance comments section of the clould masking test
ncatted -h \
  -a comments,cloud_land_mask,o,c,"The land mask flag is 99; Missing values from the TerraScan software have a flag of zero; A measurement not on land and not missing from the TerraScan software fails the time test if it is more than 2 degrees cooler than the mean of the satellite passes in the previous 72 hrs; A measurement fails the climatology test if the temperature is more than 5 degrees colder than the climatologies calculated by NSIPP AVHRR Pathfinder and Erosion Global 9km SST Climatology (Casey, Cornillon) A description of this climatology can be found at ftp://podaac.jpl.nasa.gov/pub/documents/dataset_docs/nsipp_climatology.htm; The combined time and climatology test is not a simple combination of a failure of the time and climatology tests. In this test, the previous 72 hours or satellite passes are first passed through a climatology test, then passed through the time test. It is a sequential test, rather than two independent tests. If any measurement is fails a test, all neighboring measurements within 3km are aslo automatically failed. The flag for the time test, climatoiloty test, and sequential test are 1, 2 and 4 respectively. The integer sum of these tests tell the user which of the three tests any pixel failed. Interpretation of the flags are; 0 = passed all tests 0+0+0; 1 = failed only time test 1+0+0=1; 2 = failed only climatology test 0+2+0=2; 3 = failed time test and climatology test 1+2+0=3; 4 = failed only sequential test test  0+0+4=4; 5 = failed time test and sequential test  1+0+4=5; 6 = failed climatology test and sequential test 0+2+4=6; 7 = failed time test, climatology test and sequential test 1+2+4=7. Alternatively; Pixels that failed the time test could have flags of 1, 3, 4, 7; Pixels that failed the climatology test could have flags of 2, 3, 6, 7; Pixels that failed the sequential test could have flags of 4, 5, 6, 7" \
  $1

# Add standard names
ncatted -h \
  -a standard_name,lon,o,c,"longitude" \
  -a standard_name,lat,o,c,"latitude" \
  -a standard_name,time,o,c,"time" \
  -a standard_name,mcsst,o,c,"sea_surface_temperature" \
  $1

echo "Complete."
