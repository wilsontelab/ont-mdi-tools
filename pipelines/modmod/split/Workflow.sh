#!/bin/bash

# set environment variables
export GENOMEX_MODULES_DIR=$SUITES_DIR/genomex-mdi-tools/shared/modules
export FOCUS_POSITIONS_FILE=$TASK_DIR/focus_positions.bed

# set input basecall variables
export BASECALL_DIR=$TASK_DIR/ubam
if [ ! -d "$BASECALL_DIR" ]; then
    echo "expected to find directory: $BASECALL_DIR"
    exit 1
fi

# run read splitting to identify concatemerized oligo units
runWorkflowStep 1 split split.sh
