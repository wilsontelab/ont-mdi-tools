#!/bin/bash

# set derivative environment variables
export SHARED_SUITE=ont-mdi-tools
export SHARED_MODULES_DIR=$SUITES_DIR/$SHARED_SUITE/shared/modules
export SHARED_MODULE_DIR=$SHARED_MODULES_DIR/convert

# convert ONT read files from FAST5 to POD5
runWorkflowStep 1 align $SHARED_MODULE_DIR/convert.sh
