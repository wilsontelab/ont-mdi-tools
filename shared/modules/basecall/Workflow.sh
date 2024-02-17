#!/bin/bash

# set derivative environment variables
export SHARED_SUITE=ont-mdi-tools
export SHARED_MODULES_DIR=$SUITES_DIR/$SHARED_SUITE/shared/modules
export SHARED_MODULE_DIR=$SHARED_MODULES_DIR/basecall
export GENOMEX_SHARED_SUITE=genomex-mdi-tools
export GENOMEX_SHARED_MODULES_DIR=$SUITES_DIR/$GENOMEX_SHARED_SUITE/shared/modules
source $GENOMEX_SHARED_MODULES_DIR/genome/set_genome_vars.sh

# create temp directories
if [ "$POD5_BUFFER" = "shm" ]; then 
    source $SHARED_MODULES_DIR/utilities/shell/create_temp_dir_shm.sh
    POD5_BUFFER_DIR=$TMP_DIR_WRK_SHM; # prefer to use /dev/shm for files pod5/dorado actively use
else
    source $SHARED_MODULES_DIR/utilities/shell/create_temp_dir_small.sh
    POD5_BUFFER_DIR=$TMP_DIR_WRK_SMALL; # but allow fall back to SSD if files too big for /dev/shm
fi

# parse MDI to Dorado options in preparation for basecalling
source $SHARED_MODULE_DIR/parse_dorado_options.sh

# convert ONT read files from POD5/FAST5 to BAM, i.e., call bases (and  maybe align reads)
runWorkflowStep 1 basecall $SHARED_MODULE_DIR/basecall.sh
