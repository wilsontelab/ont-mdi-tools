#!/bin/bash

# a utility to reduce the number of POD5 files in an ONT run
# the resulting larger files will move more easily to a job node for basecalling, etc.
# this standalone script can be used in any pipeline if environment variables are set (see below)

# unlike other standalone scripts, condense works with POD5 files where they are,
# even on a shared network drive, without copying them to a worker node
# because `pod5 merge` is not especially IO intensive

# the following environment variables are required and must be set or errors will occur:
#   EXPANDED_INPUT_DIR = fully expanded path(s) to one or more space-delimited directories containing input pod5 files
#                        output files are placed into ${EXPANDED_INPUT_DIR}_condensed

# the following environment variables are required but have default values:
#   POD5_BATCH_SIZE = number of pod5 files to condense per output file, defaults to 50
#   N_CPU = the number of threads to use for calls to `pod5`, defaults to 4

# set default variable values
if [ "$POD5_BATCH_SIZE" == "" ]; then POD5_BATCH_SIZE=50; fi
if [ "$N_CPU" == "" ]; then N_CPU=4; fi

# begin log report
echo "condensing POD5 files"
echo "  pod5 batch size:    "${POD5_BATCH_SIZE}
echo "  input:              "${EXPANDED_INPUT_DIR}

for WORKING_INPUT_DIR in ${EXPANDED_INPUT_DIR}; do
echo
echo "processing $WORKING_INPUT_DIR"
echo

# initialize pod5 sources
cd ${WORKING_INPUT_DIR}
CHECK_COUNT=`ls -1 *.pod5 2>/dev/null | wc -l`
if [ "$CHECK_COUNT" == "0" ]; then
    echo "fatal error: no POD5 files found in directory"
    exit 1
else
    POD5_FILES=(*.pod5)
fi

# check the output directory
OUTPUT_DIR=${WORKING_INPUT_DIR}_condensed
if [ -d "$OUTPUT_DIR" ]; then
    echo "directory already exists"
    echo "$OUTPUT_DIR"
    echo "it must be manually removed before proceeeding, condense will not overwrite it"
    continue
fi
mkdir -p ${OUTPUT_DIR}

# do the work
for ((BATCH_I=0; BATCH_I < ${#POD5_FILES[@]}; BATCH_I+=POD5_BATCH_SIZE)); do 
    echo "  batch $BATCH_I"
    BATCH_FILES=${POD5_FILES[@]:BATCH_I:POD5_BATCH_SIZE}
    pod5 merge --threads ${N_CPU} --output ${OUTPUT_DIR}/batch-$BATCH_I.pod5 $BATCH_FILES
done

# close the input directory loop
done


# $ pod5 merge --help
# usage: pod5 merge [-h] -o OUTPUT [-r] [-f] [-t THREADS] [-R READERS] [-D] inputs [inputs ...]

# Merge multiple pod5 files

# positional arguments:
#   inputs                Pod5 filepaths to use as inputs

# options:
#   -h, --help            show this help message and exit
#   -o OUTPUT, --output OUTPUT
#                         Output filepath (default: None)
#   -r, --recursive       Search for input files recursively matching `*.pod5` (default: False)
#   -f, --force-overwrite
#                         Overwrite destination files (default: False)
#   -t THREADS, --threads THREADS
#                         Number of workers (default: 4)
#   -R READERS, --readers READERS
#                         number of merge readers TESTING ONLY (default: 20)
#   -D, --duplicate-ok    Allow duplicate read_ids (default: False)

# Example: pod5 merge inputs/*.pod5 merged.pod5
