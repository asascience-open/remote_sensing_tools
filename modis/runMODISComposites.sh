#!/bin/bash

/data/modis/scripts/backprocessDirectory.sh 1 /data/modis/raw /data/modis/composites/1-day 30
/data/modis/scripts/backprocessDirectory.sh 3 /data/modis/raw /data/modis/composites/3-day 30
/data/modis/scripts/backprocessDirectory.sh 7 /data/modis/raw /data/modis/composites/7-day 30
