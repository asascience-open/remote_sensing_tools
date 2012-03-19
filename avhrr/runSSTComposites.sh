#!/bin/bash
/data/remote_sensing/scripts/makeComposite.sh 1 /data/remote_sensing/SST /data/remote_sensing/masked /data/remote_sensing/composites/1-day
/data/remote_sensing/scripts/makeComposite.sh 3 /data/remote_sensing/SST /data/remote_sensing/masked /data/remote_sensing/composites/3-day
/data/remote_sensing/scripts/makeComposite.sh 7 /data/remote_sensing/SST /data/remote_sensing/masked /data/remote_sensing/composites/7-day
