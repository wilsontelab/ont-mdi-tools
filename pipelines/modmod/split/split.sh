#!/bin/bash

# get the input bam files
cd $BASECALL_DIR
export BAM_FILES=`ls -1 *.bam`

# do the work
echo "finding oligo units in reads"
perl $ACTION_DIR/split.pl
checkPipe

# concatenate the bams for Remora
echo "concatenating and sorting bams"
cd $TASK_DIR
export BAM_DIRS=(bam_*)
for ((BASE_I=0; BASE_I < ${#BAM_DIRS[@]}; BASE_I+=1)); do 
    BAM_DIR=${BAM_DIRS[@]:BASE_I:1}
    BASE_NAME=`echo $BAM_DIR | sed 's/bam_//'`
    BAM_OUT_FILE=$BASE_NAME.chunks.bam

    echo "  $BASE_NAME"

    # TODO: consider converting supplemental to primary, since Remora won't use supplemental

    samtools cat $BAM_DIR/*.bam | 
    samtools sort -o $BAM_OUT_FILE - # plotting requires sorted bams
    checkPipe

    rm -f $BAM_OUT_FILE.bai
    samtools index $BAM_OUT_FILE
    checkPipe
done

echo "done"
