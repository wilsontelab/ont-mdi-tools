#!/bin/bash

# set derivative environment variables
export SHARED_SUITE=ont-mdi-tools
export SHARED_MODULES_DIR=$SUITES_DIR/$SHARED_SUITE/shared/modules
export SHARED_MODULE_DIR=$SHARED_MODULES_DIR/filter

# create temp directories
source $SHARED_MODULES_DIR/utilities/shell/create_temp_dir_small.sh
FILTER_CACHE_DIR=$TMP_DIR_WRK_SMALL # for holding filtered POD5 data sets prior to merging
if [ "$POD5_BUFFER" = "shm" ]; then 
    source $SHARED_MODULES_DIR/utilities/shell/create_temp_dir_shm.sh
    POD5_BUFFER_DIR=$TMP_DIR_WRK_SHM; # prefer to use /dev/shm for files pod5/dorado actively use
else
    POD5_BUFFER_DIR=$TMP_DIR_WRK_SMALL; # but allow fall back to SSD if files too big for /dev/shm
fi

# parse MDI options in preparation for repacking
EXPANDED_INPUT_DIR=`echo ${INPUT_DIR}`

# pipeline must define a script to write
#   read ids into READ_IDS_FILES
#   pairwise POD5_OUTPUT_FILES
source $PIPELINE_DIR/filter/$READ_IDS_SCRIPT  

# convert one or more POD5 files from a single ONT run to one POD5 file per channel group
# this is important for read duplexing to work properly when POD5 files are processed in batches
runWorkflowStep 1 filter $SHARED_MODULE_DIR/filter.sh
