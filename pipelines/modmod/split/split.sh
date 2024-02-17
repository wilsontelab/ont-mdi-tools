#!/bin/bash

# get the input bam files
cd $BASECALL_DIR
export BAM_FILES=`ls -1 *.bam`

# do the work
echo "finding oligo units in reads"
perl $ACTION_DIR/split.pl
checkPipe

echo "done"
