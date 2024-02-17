#!/bin/bash

# run Dorado basecall|duplex on a cluster compute node, with optimized file transfer
# this standalone script can be used in any pipeline if environment variables are set (see below)

# Dorado will use all resources, e.g., GPUs, available to the running job
# you must also request sufficient CPUs and RAM
# many configurations are possible depending on your system, here is one we use in duplex mode:
#   resources:
#     n-cpu: 8
#     n-gpu: a40:4
#     ram-per-cpu: 12G
#     tmp-dir-large: /tmp
#   job-manager:
#     time-limit: 24:00:00
#     partition: spgpu

# advantages of using batch processing on a compute node include:
#   simultaneous file copying and base calling
#   minimizes the chances of Dorado crashing late in a run, e.g., due to OOM kills
#   facilitates friendly re-start, where batches with existing output files are skipped
# disadvantages include:
#   multiple output files
#   overhead of repeating some Dorado actions in multiple startups, e.g., minimap2 indexing

# the following environment variables are required and must be set or errors will occur:
#   ONT_MODEL_DIR = a directory containing the required ONT model files, e.g., /path/to/dna_r10.4.1_e8.2_400bps_sup@v4.3.0
#   EXPANDED_INPUT_DIR = fully expanded path(s) to one or more space-delimited directories containing input pod5 (or fast5) files
#   BAM_DIR = a directory where output bam files will be written; will be created; existing batch files in BAM_DIR will not be re-created

# the following environment variables are required but have default values:
#   DORADO_EXECUTABLE = path to a Dorado executable, e.g., /path/to/dorado-0.5.3-linux-x64/bin/dorado, defaults to dorado (i.e., assumes dorado in $PATH)
#   POD5_BUFFER_DIR = a fast directory on the node to use as a batch-level POD5 cache, will be created, defaults to /dev/shm/dorado
#   POD5_BATCH_SIZE = number of pod5 files to copy and process in one batch, defaults to 50

# the following environment variables are optional and can be left unset:
#   MOD_MODEL_DIR = a directory containing optional modified base model files
#   MODIFIED_BASE = unmodified base value for MOD_MODEL_DIR, i.e, A, C, G or T
#   DUPLEX = set to any string other than "0" to run Dorado in duplex mode (incompatible with modified base calling) 
#   EMIT_MOVES = set to any string other than "0" to output moves in the output bam files
#   READ_IDS_FILE = path to a file of read ids compatible with Dorado option --read-ids
#   ALIGN_READS = set to any string other than "0" to have Dorado also align reads using minimap2, with options --secondary=no -Y
#   GENOME_FASTA = path to the required genome fasta file if ALIGN_READS is set
#   BANDWIDTH = setting for the minimap2 --bandwidth (-r) option; uses minimap2 default otherwise
#   DORADO_OPTIONS = additional options passed directly to the dorado basecaller or duplex command, e.g., "--no-trim"
#   FORCE_BASECALLING = set to any string other than "0" to force overwrite of any existing bam files

# POD5_BUFFER_DIR must have free space matching:
#   two input batches of POD5 files
#   plus the smaller space required to store one batch's bam files

# example storage math (numbers are from an actual use case):
#   570G = total input data in ${EXPANDED_INPUT_DIR}/*.pod5
#   50 = POD5_BATCH_SIZE
#   2178 = number of POD5 files in ${EXPANDED_INPUT_DIR}
#   570G / 2178 * 50 * 2 = 26G = average minimum capacity of POD5_BUFFER_DIR during basecalling
# because data are never distributed evenly, and to account for bam caching, POD5_BUFFER_DIR should be at least twice as big:
#   26G * 2 = 52G, as an estimate

# set default variable values
if [ "$DORADO_EXECUTABLE" == "" ]; then DORADO_EXECUTABLE=dorado; fi
if [ "$POD5_BUFFER_DIR" == "" ]; then POD5_BUFFER_DIR=/dev/shm/dorado; fi
if [ "$POD5_BATCH_SIZE" == "" ]; then POD5_BATCH_SIZE=50; fi

# parse option values
MODIFIED_BASE_MODEL="NA"
MODIFICATION_OPTIONS=""
if [ "$MOD_MODEL_DIR" != "" ]; then 
    MODIFIED_BASE_MODEL=`basename ${MOD_MODEL_DIR}`
    if [ "$MODIFIED_BASE" == "" ]; then
        echo "MODIFIED_BASE is required if MOD_MODEL_DIR is set"
        exit 1
    fi
    MODIFICATION_OPTIONS="--modified-bases ${MODIFIED_BASE} --modified-bases-models ${MOD_MODEL_DIR}"
fi
IS_DUPLEX="false"
if [[ "$DUPLEX" != "" && "$DUPLEX" != "0" ]]; then IS_DUPLEX="true"; fi
DORADO_COMMAND="basecaller"
if [ "$IS_DUPLEX" == "true" ]; then
    DORADO_COMMAND="duplex"
    if [ "$MODIFIED_BASE_MODEL" != "NA" ]; then
        echo "duplex basecalling and modified basecalling are incompatible at this time"
        exit 1
    fi
fi
EMITTING_MOVES="false"
if [[ "$EMIT_MOVES" != "" && "$EMIT_MOVES" != "0" ]]; then
    EMITTING_MOVES="true"
    EMIT_MOVES="--emit-moves"
else
    EMIT_MOVES=""
fi
READ_IDS_FILE_NAME="NA"
if [ "$READ_IDS_FILE" != "" ]; then 
    READ_IDS_FILE_NAME=`basename ${READ_IDS_FILE}`
    READ_IDS_FILE="--read-ids $READ_IDS_FILE"
fi
if [[ "$ALIGN_READS" != "" && "$ALIGN_READS" != "0" ]]; then IS_ALIGNING="and aligning reads"; fi
if [ "$IS_ALIGNING" != "" ]; then 
    if [ "$BANDWIDTH" != "" ]; then BANDWIDTH="--bandwidth $BANDWIDTH"; fi
    if [ "$GENOME_FASTA" == "" ]; then
        echo "GENOME_FASTA is required if ALIGN_READS is set"
        exit 1
    fi
    MINIMAP2_OPTIONS="--reference ${GENOME_FASTA} --secondary=no -Y $BANDWIDTH" 
fi
if [ "$DORADO_OPTIONS" == "NA" ]; then DORADO_OPTIONS=""; fi
if [[ "$FORCE_BASECALLING" != "" && "$FORCE_BASECALLING" != "0" ]]; then FORCE_BASECALLING="true"; fi

# begin log report
echo "calling bases $IS_ALIGNING"
echo "  Dorado version: "${DORADO_EXECUTABLE}
echo "  model:          "`basename ${ONT_MODEL_DIR}`
echo "  modification:   "${MODIFIED_BASE_MODEL}
echo "  duplex:         "${IS_DUPLEX}
echo "  emit moves:     "${EMITTING_MOVES} 
echo "  reads file:     "${READ_IDS_FILE_NAME}  
echo "  with options:   "${DORADO_OPTIONS}
echo "  pod5 buffer:    "${POD5_BUFFER_DIR}
echo "  input(s):       "${EXPANDED_INPUT_DIR}
echo "  output folder:  "${BAM_DIR}

# prepare the cache and output directories
mkdir -p ${POD5_BUFFER_DIR}
mkdir -p ${BAM_DIR}
rm -rf ${POD5_BUFFER_DIR}/*

# functions for copy and calling a batch of pod5 files
do_batch_copy () {
    if [ "$COPY_OUT_I" != "" ]; then
        COPY_OUT_DIR=$POD5_BUFFER_DIR/${BATCH_PREFIX}_$COPY_OUT_I
        if [ "$IS_ALIGNING" != "" ]; then
            BATCH_OUTPUT_FILE2=$BAM_DIR/${BATCH_PREFIX}_$COPY_OUT_I.bam
        else 
            BATCH_OUTPUT_FILE2=$BAM_DIR/${BATCH_PREFIX}_$COPY_OUT_I.unaligned.bam
        fi
        if [[ ! -f $BATCH_OUTPUT_FILE2 || "$FORCE_BASECALLING" == "true" ]]; then
            mv -f $COPY_OUT_DIR/out/*.bam $BAM_DIR
        fi
        rm -fr $COPY_OUT_DIR
    fi
    if [ "$COPY_IN_I" != "" ]; then
        if [ "$IS_ALIGNING" != "" ]; then
            BATCH_OUTPUT_FILE1=$BAM_DIR/${BATCH_PREFIX}_$COPY_IN_I.bam
        else 
            BATCH_OUTPUT_FILE1=$BAM_DIR/${BATCH_PREFIX}_$COPY_IN_I.unaligned.bam
        fi
        if [[ ! -f $BATCH_OUTPUT_FILE1 || "$FORCE_BASECALLING" == "true" ]]; then
            COPY_IN_DIR=$POD5_BUFFER_DIR/${BATCH_PREFIX}_$COPY_IN_I
            mkdir -p $COPY_IN_DIR/in
            mkdir -p $COPY_IN_DIR/out
            BATCH_FILES=${POD5_FILES[@]:COPY_IN_I:POD5_BATCH_SIZE}
            cp $BATCH_FILES $COPY_IN_DIR/in
        fi
    fi
}
RUN_DORADO="$DORADO_EXECUTABLE $DORADO_COMMAND $DORADO_OPTIONS $MODIFICATION_OPTIONS $EMIT_MOVES $READ_IDS_FILE $MINIMAP2_OPTIONS $ONT_MODEL_DIR"
run_batch_process () {
    PROCESS_DIR=$POD5_BUFFER_DIR/${BATCH_PREFIX}_$PROCESS_I
    if [ "$IS_ALIGNING" != "" ]; then 
        BATCH_OUTPUT_FILE3=$BAM_DIR/${BATCH_PREFIX}_$PROCESS_I.bam
        TMP_OUPUT_FILE=$PROCESS_DIR/out/${BATCH_PREFIX}_$PROCESS_I.bam
    else 
        BATCH_OUTPUT_FILE3=$BAM_DIR/${BATCH_PREFIX}_$PROCESS_I.unaligned.bam
        TMP_OUPUT_FILE=$PROCESS_DIR/out/${BATCH_PREFIX}_$PROCESS_I.unaligned.bam
    fi
    if [[ ! -f $BATCH_OUTPUT_FILE3 || "$FORCE_BASECALLING" == "true" ]]; then
        $RUN_DORADO $PROCESS_DIR/in > $TMP_OUPUT_FILE
    fi
    rm -fr $PROCESS_DIR/in
}

# process one pod5 input directory at a time; output is merged into a single output directory
WORKING_I=0
for WORKING_INPUT_DIR in ${EXPANDED_INPUT_DIR}; do

echo
echo "processing $WORKING_INPUT_DIR"
WORKING_I=$((WORKING_I + 1))
BATCH_PREFIX="batch_$WORKING_I"

# initialize pod5 sources
cd ${WORKING_INPUT_DIR}
CHECK_COUNT=`ls -1 *.pod5 2>/dev/null | wc -l`
if [ "$CHECK_COUNT" == "0" ]; then
    POD5_FILES=(*.fast5) # support implicit fallback to fast5 instead of the preferred pod5
else
    POD5_FILES=(*.pod5)
fi

# run basecaller one pod5 batch at a time, working from /dev/shm
# once the loop is running, one batch is copying while another batch is basecalling
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

# end input directory loop
done


# VERSION 0.5.3
# important changes: 

# added --trim/--no-trim options to basecaller only (not duplex)
# however, duplex reads will have the adapters trimmed off anyway per:
#   https://github.com/nanoporetech/dorado/issues/509
#   https://github.com/nanoporetech/dorado/issues/510
# also note that: chimeric read splitting is enabled for both duplex and simplex basecalling by default
# however, some chimeric reads with unsplittable junctions escape duplex detection

# automated model selection, although in general we don't intend to use this feature:
#    model {fast,hac,sup}@v{version} for automatic model selection including modbases, or path to existing model directory
#    (fast|hac|sup)[@(version|latest)][,modification[@(version|latest)]][,...]


# $ ./dorado basecaller --help
# Usage: dorado [-h] [--device VAR] [--read-ids VAR] [--resume-from VAR] [--max-reads VAR] [--min-qscore VAR] [--batchsize VAR] [--chunksize VAR] [--overlap VAR] [--recursive] [--modified-bases VAR...] [--modified-bases-models VAR] [--modified-bases-threshold VAR] [--emit-fastq] [--emit-sam] [--emit-moves] [--reference VAR] [--kit-name VAR] [--barcode-both-ends] [--no-trim] [--trim VAR] [--sample-sheet VAR] [--barcode-arrangement VAR] [--barcode-sequences VAR] [--estimate-poly-a] [-k VAR] [-w VAR] [-I VAR] [--secondary VAR] [-N VAR] [-Y] [--bandwidth VAR] model data

# Positional arguments:
#   model                         model selection {fast,hac,sup}@v{version} for automatic model selection including modbases, or path to existing model directory 
#   data                          the data directory or file (POD5/FAST5 format). 

# Optional arguments:
#   -h, --help                    shows help message and exits 
#   -v, --verbose             
#   -x, --device                  device string in format "cuda:0,...,N", "cuda:all", "metal", "cpu" etc.. [default: "cuda:all"]
#   -l, --read-ids                A file with a newline-delimited list of reads to basecall. If not provided, all reads will be basecalled [default: ""]
#   --resume-from                 Resume basecalling from the given HTS file. Fully written read records are not processed again. [default: ""]
#   -n, --max-reads               [default: 0]
#   --min-qscore                  Discard reads with mean Q-score below this threshold. [default: 0]
#   -b, --batchsize               if 0 an optimal batchsize will be selected. batchsizes are rounded to the closest multiple of 64. [default: 0]
#   -c, --chunksize               [default: 10000]
#   -o, --overlap                 [default: 500]
#   -r, --recursive               Recursively scan through directories to load FAST5 and POD5 files 
#   --modified-bases              [nargs: 1 or more] 
#   --modified-bases-models       a comma separated list of modified base models [default: ""]
#   --modified-bases-threshold    the minimum predicted methylation probability for a modified base to be emitted in an all-context model, [0, 1] [default: 0.05]
#   --emit-fastq                  Output in fastq format. 
#   --emit-sam                    Output in SAM format. 
#   --emit-moves              
#   --reference                   Path to reference for alignment. [default: ""]
#   --kit-name                    Enable barcoding with the provided kit name. Choose from: EXP-NBD103 EXP-NBD104 EXP-NBD114 EXP-NBD196 EXP-PBC001 EXP-PBC096 SQK-16S024 SQK-16S114-24 SQK-LWB001 SQK-MLK111-96-XL SQK-MLK114-96-XL SQK-NBD111-24 SQK-NBD111-96 SQK-NBD114-24 SQK-NBD114-96 SQK-PBK004 SQK-PCB109 SQK-PCB110 SQK-PCB111-24 SQK-PCB114-24 SQK-RAB201 SQK-RAB204 SQK-RBK001 SQK-RBK004 SQK-RBK110-96 SQK-RBK111-24 SQK-RBK111-96 SQK-RBK114-24 SQK-RBK114-96 SQK-RLB001 SQK-RPB004 SQK-RPB114-24 VSK-PTC001 VSK-VMK001 VSK-VMK004 VSK-VPS001. 
#   --barcode-both-ends           Require both ends of a read to be barcoded for a double ended barcode. 
#   --no-trim                     Skip trimming of barcodes, adapters, and primers. If option is not chosen, trimming of all three is enabled. 
#   --trim                        Specify what to trim. Options are 'none', 'all', 'adapters', and 'primers'. Default behavior is to trim all detected adapters, primers, or barcodes. Choose 'adapters' to just trim adapters. The 'primers' choice will trim adapters and primers, but not barcodes. The 'none' choice is equivelent to using --no-trim. Note that this only applies to DNA. RNA adapters are always trimmed. [default: ""]
#   --sample-sheet                Path to the sample sheet to use. [default: ""]
#   --barcode-arrangement         Path to file with custom barcode arrangement. [default: <not representable>]
#   --barcode-sequences           Path to file with custom barcode sequences. [default: <not representable>]
#   --estimate-poly-a             Estimate poly-A/T tail lengths (beta feature). Primarily meant for cDNA and dRNA use cases. Note that if this flag is set, then adapter/primer detection will be disabled. 
#   -k                            minimap2 k-mer size for alignment (maximum 28). [default: 15]
#   -w                            minimap2 minimizer window size for alignment. [default: 10]
#   -I                            minimap2 index batch size. [default: "16G"]
#   --secondary                   minimap2 outputs secondary alignments [default: "yes"]
#   -N                            minimap2 retains at most INT secondary alignments [default: 5]
#   -Y                            minimap2 uses soft clipping for supplementary alignments 
#   --bandwidth                   minimap2 chaining/alignment bandwidth and optionally long-join bandwidth specified as NUM,[NUM] [default: "500,20K"]


# $ ./dorado duplex --help
# Usage: dorado [-h] [--pairs VAR] [--emit-fastq] [--emit-sam] [--threads VAR] [--device VAR] [--batchsize VAR] [--chunksize VAR] [--overlap VAR] [--recursive] [--read-ids VAR] [--min-qscore VAR] [--reference VAR] [--modified-bases VAR...] [--modified-bases-models VAR] [--modified-bases-threshold VAR] [-k VAR] [-w VAR] [-I VAR] [--secondary VAR] [-N VAR] [-Y] [--bandwidth VAR] model reads

# Positional arguments:
#   model                         model selection {fast,hac,sup}@v{version} for automatic model selection including modbases, or path to existing model directory 
#   reads                         Reads in POD5 format or BAM/SAM format for basespace. 

# Optional arguments:
#   -h, --help                    shows help message and exits 
#   --pairs                       Space-delimited csv containing read ID pairs. If not provided, pairing will be performed automatically [default: ""]
#   --emit-fastq              
#   --emit-sam                    Output in SAM format. 
#   -t, --threads                 [default: 0]
#   -x, --device                  device string in format "cuda:0,...,N", "cuda:all", "metal" etc.. [default: "cuda:all"]
#   -b, --batchsize               if 0 an optimal batchsize will be selected. batchsizes are rounded to the closest multiple of 64. [default: 0]
#   -c, --chunksize               [default: 10000]
#   -o, --overlap                 [default: 500]
#   -r, --recursive               Recursively scan through directories to load FAST5 and POD5 files 
#   -l, --read-ids                A file with a newline-delimited list of reads to basecall. If not provided, all reads will be basecalled [default: ""]
#   --min-qscore                  Discard reads with mean Q-score below this threshold. [default: 0]
#   --reference                   Path to reference for alignment. [default: ""]
#   -v, --verbose             
#   --modified-bases              [nargs: 1 or more] 
#   --modified-bases-models       a comma separated list of modified base models [default: ""]
#   --modified-bases-threshold    the minimum predicted methylation probability for a modified base to be emitted in an all-context model, [0, 1] [default: 0.05]
#   -k                            minimap2 k-mer size for alignment (maximum 28). [default: 15]
#   -w                            minimap2 minimizer window size for alignment. [default: 10]
#   -I                            minimap2 index batch size. [default: "16G"]
#   --secondary                   minimap2 outputs secondary alignments [default: "yes"]
#   -N                            minimap2 retains at most INT secondary alignments [default: 5]
#   -Y                            minimap2 uses soft clipping for supplementary alignments 
#   --bandwidth                   minimap2 chaining/alignment bandwidth and optionally long-join bandwidth specified as NUM,[NUM] [default: "500,20K"]
