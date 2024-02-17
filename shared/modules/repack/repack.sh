#!/bin/bash

# convert a set of POD5 files from a single ONT run to one POD5 file per channel group,
# working on a cluster compute node, with optimized file transfers
# this standalone script can be used in any pipeline if environment variables are set (see below)

# many configurations are possible depending on your system, here is one we use:
#   resources:
#     n-cpu: 8
#     ram-per-cpu: 12G
#     tmp-dir-large: /tmp
#   job-manager:
#     time-limit: 6:00:00

# the following environment variables are required and must be set or errors will occur:
#   EXPANDED_INPUT_DIR = fully expanded path(s) to one or more space-delimited directories containing input pod5 files
#                        output files will be written to ${EXPANDED_INPUT_DIR}_by_channel_group

# the following environment variables are required but have default values:
#   POD5_BUFFER_DIR = a fast directory on the node to use as a batch-level POD5 cache, will be created, defaults to /dev/shm/pod5_repack
#   INPUT_CACHE_DIR = directory typically local to the node to use as an input-level cache, will be created, defaults to /tmp/pod5_repack
#   POD5_BATCH_SIZE = number of pod5 files to copy and process in one batch, defaults to 50
#   CHANNEL_GROUP_SIZE = number of nanopore channels to combine into a single channel_group output pod5 file, defaults to 50
#   N_CPU = the number of threads to use for calls to `pod5`, defaults to 4

# the following environment variables are optional and can be left unset:
#   FORCE_REPACKING = set to any string other than "0" to force repacking even if directory '${EXPANDED_INPUT_DIR}_by_channel_group' exists

# POD5_BUFFER_DIR must have free space matching:
#   three input batches of POD5 files before subsetting
#   three copies of any channel group's collective data files after subsetting
# INPUT_CACHE_DIR must have free space matching:
#   the set of all POD5 files derived from any one EXPANDED_INPUT_DIR

# example storage math (numbers are from an actual use case):
#   570G = total input data in ${EXPANDED_INPUT_DIR}/*.pod5, required size of INPUT_CACHE_DIR
#   50 = POD5_BATCH_SIZE
#   50 = CHANNEL_GROUP_SIZE
#   2178 = number of POD5 files in ${EXPANDED_INPUT_DIR}
#   2978 = maximum Promethion channel number
#   570G / 2178 * 50 * 3 = 39G = average minimum capacity of POD5_BUFFER_DIR during subsetting
#   570G / 2978 * 50 * 3 = 29G = average minimum capacity of POD5_BUFFER_DIR during merging
# because data are never distributed evenly, POD5_BUFFER_DIR should be at least twice as big:
#   39G * 2 = 78G, as an estimate

#--------------------------------------------------------------------------------
# GET READY
#--------------------------------------------------------------------------------

# set default variable values
if [ "$POD5_BUFFER_DIR" == "" ]; then POD5_BUFFER_DIR=/dev/shm/pod5_repack; fi
if [ "$INPUT_CACHE_DIR" == "" ]; then INPUT_CACHE_DIR=/tmp/pod5_repack; fi
if [ "$POD5_BATCH_SIZE" == "" ]; then POD5_BATCH_SIZE=50; fi
if [ "$CHANNEL_GROUP_SIZE" == "" ]; then CHANNEL_GROUP_SIZE=50; fi
if [ "$N_CPU" == "" ]; then N_CPU=4; fi
if [[ "$FORCE_REPACKING" != "" && "$FORCE_REPACKING" != "0" ]]; then FORCE_REPACKING="true"; fi

# begin log report
echo "repacking POD5 files by channel group"
echo "  pod5 buffer:        "${POD5_BUFFER_DIR}
echo "  input cache:        "${INPUT_CACHE_DIR}
echo "  pod5 batch size:    "${POD5_BATCH_SIZE}
echo "  channels per group: "${CHANNEL_GROUP_SIZE}
echo "  input(s):           "${EXPANDED_INPUT_DIR}

# prepare the cache directories
mkdir -p ${POD5_BUFFER_DIR}
mkdir -p ${INPUT_CACHE_DIR}
rm -rf ${POD5_BUFFER_DIR}/*
rm -f ${INPUT_CACHE_DIR}/*.pod5

#--------------------------------------------------------------------------------
# INPUT DIRECTORY LOOP: process one pod5 input directory at a time
#--------------------------------------------------------------------------------
WORKING_I=0
for WORKING_INPUT_DIR in ${EXPANDED_INPUT_DIR}; do

# prepare the output directories
echo
echo "processing $WORKING_INPUT_DIR"
WORKING_I=$((WORKING_I + 1))
BATCH_PREFIX="batch_$WORKING_I"
REPACK_OUTPUT_DIR=${WORKING_INPUT_DIR}_by_channel_group
if [[ -d $REPACK_OUTPUT_DIR && "$FORCE_REPACKING" != "true" ]]; then
    echo "output directory already exists and FORCE_REPACKING not set"
    echo "$REPACK_OUTPUT_DIR"
    echo "nothing to do"
    continue # next EXPANDED_INPUT_DIR
fi
mkdir -p ${REPACK_OUTPUT_DIR}
rm -f ${REPACK_OUTPUT_DIR}/*.pod5

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
# REPACK STAGE 1 - `pod5 view` with post-processing to establish channel groups
#--------------------------------------------------------------------------------

# `view` is sufficiently fast even on a shared network drive
echo "indexing input read ids: pod5 view"
POD5_SUMMARY_FILE=${INPUT_CACHE_DIR}/pod5.summary.tsv
pod5 view ${WORKING_INPUT_DIR} --threads ${N_CPU} --force-overwrite --include "read_id, channel" --output ${POD5_SUMMARY_FILE}.tmp
awk 'BEGIN{OFS = "\t"}{
    print $0, $1 ~ /read_id/ ? "channel_group" : int($2 / '$CHANNEL_GROUP_SIZE');
}' ${POD5_SUMMARY_FILE}.tmp > ${POD5_SUMMARY_FILE}
rm -f ${POD5_SUMMARY_FILE}.tmp

#--------------------------------------------------------------------------------
# REPACK STAGE 2 - `pod5 subset` to repack by channel group
#--------------------------------------------------------------------------------

# functions for copying and processing a batch of pod5 files
do_batch_copy () {
    if [ "$COPY_OUT_I" != "" ]; then
        COPY_OUT_DIR=$POD5_BUFFER_DIR/${BATCH_PREFIX}_$COPY_OUT_I
        mv -f $COPY_OUT_DIR/out/*.pod5 ${INPUT_CACHE_DIR}
        rm -fr $COPY_OUT_DIR
    fi
    if [ "$COPY_IN_I" != "" ]; then
        COPY_IN_DIR=$POD5_BUFFER_DIR/${BATCH_PREFIX}_$COPY_IN_I
        mkdir -p $COPY_IN_DIR/in
        mkdir -p $COPY_IN_DIR/out
        BATCH_FILES=${POD5_FILES[@]:COPY_IN_I:POD5_BATCH_SIZE}
        cp $BATCH_FILES $COPY_IN_DIR/in
    fi
}
run_batch_process () {
    PROCESS_DIR=$POD5_BUFFER_DIR/${BATCH_PREFIX}_$PROCESS_I
    pod5 subset ${PROCESS_DIR}/in --threads ${N_CPU} --force-overwrite --summary ${POD5_SUMMARY_FILE} \
        --missing-ok --columns channel_group --output ${PROCESS_DIR}/out --template channel_group-{channel_group}.batch-$PROCESS_I.pod5
    rm -fr ${PROCESS_DIR}/in
}

# repack one pod5 file batch at a time, working from /dev/shm
# once the loop is running, one batch is copying while another batch is repacking
echo "subsetting by channel group: pod5 subset"
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
# REPACK STAGE 3 - `pod5 merge` to reduce to a manageable number of files for batched basecalling
#--------------------------------------------------------------------------------

echo
echo "collecting unique channel groups"
CHANNEL_GROUPS=(`cut -f 3 ${POD5_SUMMARY_FILE} | grep -v "channel_group" | sort -k1,1n --parallel ${N_CPU} | uniq`)
rm -rf ${POD5_BUFFER_DIR}/*

# functions for copying and processing a batch of pod5 files
do_batch_copy2 () {
    if [ "$COPY_OUT_I" != "" ]; then
        COPY_OUT_DIR=$POD5_BUFFER_DIR/${BATCH_PREFIX}_$COPY_OUT_I
        mv -f $COPY_OUT_DIR/out/*.pod5 ${REPACK_OUTPUT_DIR}
        rm -fr $COPY_OUT_DIR
    fi
    if [ "$COPY_IN_I" != "" ]; then # this appears to be the slowest step during merging
        COPY_IN_DIR=$POD5_BUFFER_DIR/${BATCH_PREFIX}_$COPY_IN_I
        mkdir -p $COPY_IN_DIR/in
        mkdir -p $COPY_IN_DIR/out
        CHANNEL_GROUP=${CHANNEL_GROUPS[@]:COPY_IN_I:1}
        mv ${INPUT_CACHE_DIR}/channel_group-$CHANNEL_GROUP.* $COPY_IN_DIR/in
    fi
}
run_batch_process2 () {
    PROCESS_DIR=$POD5_BUFFER_DIR/${BATCH_PREFIX}_$PROCESS_I
    CHANNEL_GROUP=${CHANNEL_GROUPS[@]:PROCESS_I:1}
    pod5 merge --threads ${N_CPU} --output ${PROCESS_DIR}/out/channel_group-$CHANNEL_GROUP.pod5 ${PROCESS_DIR}/in/*.pod5 
    rm -fr ${PROCESS_DIR}/in
}

# merge one channel group at a time, working from /dev/shm
# once the loop is running, one channel group is copying while another is merging
echo "aggregating channel group batches: pod5 merge"
COPY_IN_I=0
COPY_OUT_I=""
echo "waiting for batch copy $COPY_IN_I"
do_batch_copy2
PROCESS_I=$COPY_IN_I
for ((COPY_IN_I=1; COPY_IN_I < ${#CHANNEL_GROUPS[@]}; COPY_IN_I+=1)); do 
    do_batch_copy2 &
    COPY_PID=$!
    run_batch_process2
    echo "waiting for batch copy $COPY_IN_I"
    wait $COPY_PID
    COPY_OUT_I=$PROCESS_I
    PROCESS_I=$COPY_IN_I
done
COPY_IN_I=""
do_batch_copy2 &
COPY_PID=$!
run_batch_process2
echo "finishing final file copy"
wait $COPY_PID
COPY_OUT_I=$PROCESS_I
do_batch_copy2

# TODO: future benchmarking
# code above results in very little time spent on processing by `pod5 merge`, apparently faster than `subset`
# consider the following alternative, unsure how it would perform over a network drive
# CHANNEL_GROUPS=`cut -f 3 ${POD5_SUMMARY_FILE} | grep -v "channel_group" | sort -k1,1n --parallel ${N_CPU} | uniq`
# for CHANNEL_GROUP in $CHANNEL_GROUPS; do 
#     pod5 merge --threads ${N_CPU} \
#         --output ${REPACK_OUTPUT_DIR}/channel_group-$CHANNEL_GROUP.pod5 \
#         ${INPUT_CACHE_DIR}/channel_group-$CHANNEL_GROUP.*.pod5 
# done

#--------------------------------------------------------------------------------
# INPUT DIRECTORY LOOP: clean up and close loop
#--------------------------------------------------------------------------------
rm -rf ${POD5_BUFFER_DIR}/*
rm -rf ${INPUT_CACHE_DIR}/*.pod5
done


# $ pod5 view --help
# usage: pod5 view [-h] [-o OUTPUT] [-r] [-f] [-t THREADS] [-H] [--separator SEPARATOR] [-I] [-i INCLUDE] [-x EXCLUDE] [-L] [inputs ...]

#     Write contents of some pod5 file(s) as a table to stdout or --output if given.
#     The default separator is <tab>.
#     The column order is always as shown in -L/--list-fields"
    
# positional arguments:
#   inputs                Input pod5 file(s) to view (default: None)

# options:
#   -h, --help            show this help message and exit
#   -o OUTPUT, --output OUTPUT
#                         Output filename (default: None)
#   -r, --recursive       Search for input files recursively matching `*.pod5` (default: False)
#   -f, --force-overwrite
#                         Overwrite destination files (default: False)
#   -t THREADS, --threads THREADS
#                         Set the number of reader workers (default: 8)

# Formatting:
#   -H, --no-header       Omit the header line (default: False)
#   --separator SEPARATOR
#                         Table separator character (e.g. ',') (default: )

# Selection:
#   -I, --ids             Only write 'read_id' field (default: False)
#   -i INCLUDE, --include INCLUDE
#                         Include a double-quoted comma-separated list of fields (default: None)
#   -x EXCLUDE, --exclude EXCLUDE
#                         Exclude a double-quoted comma-separated list of fields. (default: None)

# List Fields:
#   -L, --list-fields     List all groups and fields available for selection and exit (default: False)

# =================================================================================================

#   $ pod5 subset --help
# usage: pod5 subset [-h] [-o OUTPUT] [-r] [-f] [-t THREADS] [--csv CSV] [-s TABLE] [-R READ_ID_COLUMN] [-c COLUMNS [COLUMNS ...]] [--template TEMPLATE] [-T] [-M] [-D]
#                    inputs [inputs ...]

# Given one or more pod5 input files, take subsets of reads into one or more pod5 output files by a user-supplied mapping.

# positional arguments:
#   inputs                Pod5 filepaths to use as inputs

# options:
#   -h, --help            show this help message and exit
#   -o OUTPUT, --output OUTPUT
#                         Destination directory to write outputs
#   -r, --recursive       Search for input files recursively matching `*.pod5` (default: False)
#   -f, --force-overwrite
#                         Overwrite destination files (default: False)
#   -t THREADS, --threads THREADS
#                         Number of subsetting workers (default: 8)

# direct mapping:
#   --csv CSV             CSV file mapping output filename to read ids (default: None)

# table mapping:
#   -s TABLE, --summary TABLE, --table TABLE
#                         Table filepath (csv or tsv) (default: None)
#   -R READ_ID_COLUMN, --read-id-column READ_ID_COLUMN
#                         Name of the read_id column in the summary (default: read_id)
#   -c COLUMNS [COLUMNS ...], --columns COLUMNS [COLUMNS ...]
#                         Names of --summary / --table columns to subset on (default: None)
#   --template TEMPLATE   template string to generate output filenames (e.g. "mux-{mux}_barcode-{barcode}.pod5"). default is to concatenate all columns to values as shown
#                         in the example. (default: None)
#   -T, --ignore-incomplete-template
#                         Suppress the exception raised if the --template string does not contain every --columns key (default: None)

# content settings:
#   -M, --missing-ok      Allow missing read_ids (default: False)
#   -D, --duplicate-ok    Allow duplicate read_ids (default: False)

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
