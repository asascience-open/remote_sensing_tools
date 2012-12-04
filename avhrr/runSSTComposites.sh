#!/bin/bash

/data/remote_sensing/scripts/backprocessDirectory.sh 1 /data/remote_sensing/SST /data/remote_sensing/masked /data/remote_sensing/composites/1-day 30
/data/remote_sensing/scripts/backprocessDirectory.sh 3 /data/remote_sensing/SST /data/remote_sensing/masked /data/remote_sensing/composites/3-day 30
/data/remote_sensing/scripts/backprocessDirectory.sh 7 /data/remote_sensing/SST /data/remote_sensing/masked /data/remote_sensing/composites/7-day 30
