# extract all unique read ids that generated chunks in the split action
# write to a file for passing to filter.sh standalone script

echo "discovering bases"
cd $TASK_DIR
export BAM_DIRS=(bam_*)
export READ_IDS_FILES=(`ls -1d bam_* | sed 's/bam_//' | awk '{print "'$DATA_FILE_PREFIX'."$1".read_ids.txt"}'`)
export POD5_OUTPUT_FILES=(`ls -1d bam_* | sed 's/bam_//' | awk '{print "'$DATA_FILE_PREFIX'."$1".filtered.pod5"}'`)

echo "extracting read ids per base"
for ((BASE_I=0; BASE_I < ${#BAM_DIRS[@]}; BASE_I+=1)); do 
    BAM_DIR=${BAM_DIRS[@]:BASE_I:1}
    READ_IDS_FILE=${READ_IDS_FILES[@]:BASE_I:1}
    BAM_FILES=($BAM_DIR/*.bam)

    echo $BAM_DIR
    rm -f $READ_IDS_FILE
    for BAM_FILE in "${BAM_FILES[@]}"; do 
        echo "  $BAM_FILE"
        samtools view $BAM_FILE | 
        cut -f 1 | 
        uniq >> $READ_IDS_FILE  # each file is already name sorted
    done

    echo $READ_IDS_FILE
    head $READ_IDS_FILE
    echo "..."
    echo `cat $READ_IDS_FILE | wc -l`" unique read ids"
    echo
done

# convert to space delimited strings for filter.sh
export READ_IDS_FILES="${READ_IDS_FILES[*]}"
export POD5_OUTPUT_FILES="${POD5_OUTPUT_FILES[*]}"
