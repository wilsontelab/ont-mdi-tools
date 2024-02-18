#!/bin/bash

# filter a set of POD5 files against a list of read ids to create one [much] smaller POD5,
# working on a cluster compute node, with optimized file transfers
# this standalone script can be used in any pipeline if environment variables are set (see below)

# many configurations are possible depending on your system, here is one we use:
#   resources:
#     n-cpu: 8
#     ram-per-cpu: 12G
#     tmp-dir: /tmpssd
#   job-manager:
#     time-limit: 6:00:00

# the following environment variables are required and must be set or errors will occur:
#   EXPANDED_INPUT_DIR = fully expanded path(s) to one or more space-delimited directories containing input pod5 files
#   READ_IDS_FILE = path to one file of unique read ids to filter for, one read id per file line
#   POD5_OUTPUT_FILE = path to one named output POD5 file; parent directory must exist

# the following environment variables are required but have default values:
#   POD5_BUFFER_DIR = a fast directory on the node to use as a batch-level POD5 cache, will be created, defaults to /dev/shm/pod5_filter
#   FILTER_CACHE_DIR = directory typically local to the node to use as an output cache, will be created, defaults to /tmp/pod5_filter
#   POD5_BATCH_SIZE = number of pod5 files to copy and process in one batch, defaults to 50
#   N_CPU = the number of threads to use for calls to `pod5`, defaults to 4

# the following environment variables are optional and can be left unset:
#   FORCE_FILTERING = set to any string other than "0" to force filtering even if POD5_OUTPUT_FILE exists

# POD5_BUFFER_DIR must have free space matching:
#   two input batches of POD5 files before filtering
#   plus the smaller space required to store one batch's filter hits
# FILTER_CACHE_DIR and POD5_BUFFER_DIR must have free space matching:
#   the set of all POD5 filter hits over all batches of all input directories

# example storage math (numbers are from an actual use case):
#   570G = total input data in ${EXPANDED_INPUT_DIR}/*.pod5
#   50 = POD5_BATCH_SIZE
#   2178 = number of POD5 files in ${EXPANDED_INPUT_DIR}
#   570G / 2178 * 50 * 2 = 26G = average minimum capacity of POD5_BUFFER_DIR during filtering
#   1% = filtering hit rate
#   570G * 1% = 6G = minimum capacity of FILTER_CACHE_DIR and POD5_BUFFER_DIR after filtering
# because data are never distributed evenly, POD5_BUFFER_DIR should be at least twice as big:
#   26G * 2 = 52G, as an estimate

#--------------------------------------------------------------------------------
# GET READY
#--------------------------------------------------------------------------------

# set default variable values
if [ "$POD5_BUFFER_DIR" == "" ]; then POD5_BUFFER_DIR=/dev/shm/pod5_filter; fi
if [ "$FILTER_CACHE_DIR" == "" ]; then FILTER_CACHE_DIR=/tmp/pod5_filter; fi
if [ "$POD5_BATCH_SIZE" == "" ]; then POD5_BATCH_SIZE=50; fi
if [ "$N_CPU" == "" ]; then N_CPU=4; fi
if [[ "$FORCE_FILTERING" != "" && "$FORCE_FILTERING" != "0" ]]; then FORCE_FILTERING="true"; fi

# begin log report
echo "filtering POD5 files"
echo "  pod5 buffer:        "${POD5_BUFFER_DIR}
echo "  output cache:       "${FILTER_CACHE_DIR}
echo "  pod5 batch size:    "${POD5_BATCH_SIZE}
echo "  input:              "${EXPANDED_INPUT_DIR}
echo "  read ids:           "${READ_IDS_FILE}
echo "  output:             "${POD5_OUTPUT_FILE}

# prepare the cache directories
mkdir -p ${POD5_BUFFER_DIR}
mkdir -p ${FILTER_CACHE_DIR}
rm -rf ${POD5_BUFFER_DIR}/*
rm -f ${FILTER_CACHE_DIR}/*.pod5

# check the read ids files
if [ "$READ_IDS_FILE" = "" ]; then
    echo "missing value for READ_IDS_FILE"
    exit 1
fi
if [ ! -f "$READ_IDS_FILE" ]; then
    echo "file not found: $READ_IDS_FILE"
    exit 1
fi

# prepare the output file; one file over all inputs
if [ "$POD5_OUTPUT_FILE" = "" ]; then
    echo "missing value for POD5_OUTPUT_FILE"
    exit 1
fi
if [[ -f "$POD5_OUTPUT_FILE" && "$FORCE_FILTERING" != "true" ]]; then
    echo "output file already exists and FORCE_FILTERING not set"
    echo "$POD5_OUTPUT_FILE"
    echo "nothing to do"
    exit 1
fi
rm -f ${POD5_OUTPUT_FILE}

#--------------------------------------------------------------------------------
# INPUT DIRECTORY LOOP: process one pod5 input directory at a time
#--------------------------------------------------------------------------------
WORKING_I=0
for WORKING_INPUT_DIR in ${EXPANDED_INPUT_DIR}; do

# prepare the output
echo
echo "processing $WORKING_INPUT_DIR"
WORKING_I=$((WORKING_I + 1))
BATCH_PREFIX="batch_$WORKING_I"

# initialize pod5 sources
cd ${WORKING_INPUT_DIR}
CHECK_COUNT=`ls -1 *.pod5 2>/dev/null | wc -l`
if [ "$CHECK_COUNT" == "0" ]; then
    echo "fatal error: no POD5 files found in directory"
    exit 1
else
    POD5_FILES=(*.pod5)
fi

#--------------------------------------------------------------------------------
# FILTER STAGE 1 - `pod5 filter` per file batch
#--------------------------------------------------------------------------------

# functions for copying and processing a batch of pod5 files
do_batch_copy () {
    if [ "$COPY_OUT_I" != "" ]; then
        COPY_OUT_DIR=$POD5_BUFFER_DIR/${BATCH_PREFIX}_$COPY_OUT_I
        mv -f $COPY_OUT_DIR/out/*.pod5 ${FILTER_CACHE_DIR}
        rm -fr $COPY_OUT_DIR
    fi
    if [ "$COPY_IN_I" != "" ]; then
        COPY_IN_DIR=$POD5_BUFFER_DIR/${BATCH_PREFIX}_$COPY_IN_I
        mkdir -p $COPY_IN_DIR/in
        mkdir -p $COPY_IN_DIR/out
        BATCH_FILES=${POD5_FILES[@]:COPY_IN_I:POD5_BATCH_SIZE}

        # TAR_FILE_NAME=filter_transfer_working.tar # with many small files, transfer is the slowest step, filtering on /dev/shm is very fast
        # TAR_FILE=$PWD/$TAR_FILE_NAME
        # tar -cf $TAR_FILE $BATCH_FILES
        # mv $TAR_FILE $COPY_IN_DIR/in
        # TAR_FILE=$COPY_IN_DIR/in/$TAR_FILE_NAME
        # tar -xf $TAR_FILE
        # rm -f $TAR_FILE

        cp $BATCH_FILES $COPY_IN_DIR/in
    fi
}
run_batch_process () {
    PROCESS_DIR=$POD5_BUFFER_DIR/${BATCH_PREFIX}_$PROCESS_I
    pod5 filter --threads ${N_CPU} --ids ${READ_IDS_FILE} --output ${PROCESS_DIR}/out/batch-$WORKING_I-$PROCESS_I.pod5 --missing-ok ${PROCESS_DIR}/in 
    rm -fr ${PROCESS_DIR}/in
}

# filter one pod5 file batch at a time, working from /dev/shm
# once the loop is running, one batch is copying while another batch is filtering
echo "applying pod5 filter"
COPY_IN_I=0
COPY_OUT_I=""
echo "waiting for batch copy $COPY_IN_I"
do_batch_copy
PROCESS_I=$COPY_IN_I
for ((COPY_IN_I=POD5_BATCH_SIZE; COPY_IN_I < ${#POD5_FILES[@]}; COPY_IN_I+=POD5_BATCH_SIZE)); do 
    do_batch_copy &
    COPY_PID=$!
    run_batch_process
    echo "waiting for batch copy $COPY_IN_I"
    wait $COPY_PID
    COPY_OUT_I=$PROCESS_I
    PROCESS_I=$COPY_IN_I
done
COPY_IN_I=""
do_batch_copy &
COPY_PID=$!
run_batch_process
echo "finishing final file copy"
wait $COPY_PID
COPY_OUT_I=$PROCESS_I
do_batch_copy

#--------------------------------------------------------------------------------
# INPUT DIRECTORY LOOP: clean up and close loop
#--------------------------------------------------------------------------------
done

#--------------------------------------------------------------------------------
# FILTER STAGE 2 - `pod5 merge` to reduce to a manageable number of files for batched basecalling
#--------------------------------------------------------------------------------

mkdir -p $POD5_BUFFER_DIR/in
mkdir -p $POD5_BUFFER_DIR/out
mv ${FILTER_CACHE_DIR}/batch-*-*.pod5 $POD5_BUFFER_DIR/in
pod5 merge --threads ${N_CPU} --output $POD5_BUFFER_DIR/out/merged.out.pod5 $POD5_BUFFER_DIR/in
mv $POD5_BUFFER_DIR/out/merged.out.pod5 $POD5_OUTPUT_FILE

rm -rf ${POD5_BUFFER_DIR}/*
rm -rf ${FILTER_CACHE_DIR}/*.pod5


# $ pod5 filter --help
# usage: pod5 filter [-h] [-r] [-f] -i IDS -o OUTPUT [-t THREADS] [-M] [-D] inputs [inputs ...]

# Take a subset of reads using a list of read_ids from one or more inputs

# positional arguments:
#   inputs                Pod5 filepaths to use as inputs

# options:
#   -h, --help            show this help message and exit
#   -r, --recursive       Search for input files recursively matching `*.pod5`
#   -f, --force-overwrite
#                         Overwrite destination files
#   -t THREADS, --threads THREADS
#                         Number of workers

# required arguments:
#   -i IDS, --ids IDS     A file containing a list of only valid read ids to filter from inputs
#   -o OUTPUT, --output OUTPUT
#                         Destination output filename

# content settings:
#   -M, --missing-ok      Allow missing read_ids
#   -D, --duplicate-ok    Allow duplicate read_ids

# Example: pod5 filter inputs*.pod5 --ids read_ids.txt --output filtered.pod5

# =================================================================================================

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
