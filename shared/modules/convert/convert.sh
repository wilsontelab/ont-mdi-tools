#!/bin/bash

# process and set working paths
EXPANDED_INPUT_DIR=`echo ${INPUT_DIR}`           # e.g., /path/to/ont/fast5
WORKING_DIR=`dirname ${EXPANDED_INPUT_DIR}`      # e.g., /path/to/ont
ONE_TO_ONE_PATH=`basename ${EXPANDED_INPUT_DIR}` # e.g., fast5 ==> stripped off of EXPANDED_INPUT_DIR before writing pod5/*.pod5
cd ${WORKING_DIR}

# log report
echo "converting fast5 to pod5"
echo "  input:  ${EXPANDED_INPUT_DIR}"
echo "  output: ${WORKING_DIR}/pod5"

# convert fast5 to pod5
pod5 convert fast5 --threads ${N_CPU} ./${ONE_TO_ONE_PATH}/*.fast5 --output pod5 --one-to-one ${ONE_TO_ONE_PATH}
checkPipe


# usage: pod5 convert [-h] {fast5,from_fast5,to_fast5} ...
# options:
#   -h, --help            show this help message and exit
# Example: pod5 convert fast5 input.fast5 --output output.pod5


# $ pod5 convert fast5 --help
# usage: pod5 convert fast5 [-h] -o OUTPUT [-r] [-t THREADS] [--strict] [-O ONE_TO_ONE] [-f] [--signal-chunk-size SIGNAL_CHUNK_SIZE] inputs [inputs ...]

# Convert fast5 file(s) into a pod5 file(s)

# positional arguments:
#   inputs                Input path for fast5 file

# options:
#   -h, --help            show this help message and exit
#   -r, --recursive       Search for input files recursively (default: False)
#   -t THREADS, --threads THREADS
#                         Set the number of threads to use [default: 10] (default: 10)
#   --strict              Immediately quit if an exception is encountered during conversion instead of continuing with remaining inputs after issuing a warning (default:
#                         False)

# required arguments:
#   -o OUTPUT, --output OUTPUT
#                         Output path for the pod5 file(s). This can be an existing directory (creating 'output.pod5' within it) or a new named file path. A directory must be
#                         given when using --one-to-one. (default: None)

# output control arguments:
#   -O ONE_TO_ONE, --one-to-one ONE_TO_ONE
#                         Output files are written 1:1 to inputs. 1:1 output files are written to the output directory in a new directory structure relative to the directory
#                         path provided to this argument. This directory path must be a relative parent of all inputs. (default: None)
#   -f, --force-overwrite
#                         Overwrite destination files (default: False)
#   --signal-chunk-size SIGNAL_CHUNK_SIZE
#                         Chunk size to use for signal data set (default: 102400)
