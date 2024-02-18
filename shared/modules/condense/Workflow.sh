#!/bin/bash

# set derivative environment variables
export SHARED_SUITE=ont-mdi-tools
export SHARED_MODULES_DIR=$SUITES_DIR/$SHARED_SUITE/shared/modules
export SHARED_MODULE_DIR=$SHARED_MODULES_DIR/condense

# parse MDI options in preparation for repacking
EXPANDED_INPUT_DIR=`echo ${INPUT_DIR}`

# reduce the number of POD5 files returned by MinKnow in an ONT flowcell run
runWorkflowStep 1 condense $SHARED_MODULE_DIR/condense.sh
