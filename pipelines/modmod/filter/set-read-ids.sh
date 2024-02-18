# extract all unique read ids that generated chunks in the split action
# write to a file for passing to filter.sh standalone script

export READ_IDS_FILE=$DATA_FILE_PREFIX.read_ids.txt
rm -f $READ_IDS_FILE.tmp

cd $TASK_DIR
BAM_FILES=(bam_*/*.bam)

echo "extracting read ids per file"
for BAM_FILE in "${BAM_FILES[@]}"; do 
    echo "  $BAM_FILE"
    samtools view $BAM_FILE | 
    cut -f 1 | 
    uniq >> $READ_IDS_FILE.tmp
done

echo "enforcing uniqueness"
sort --parallel $N_CPU --buffer-size 8G $READ_IDS_FILE.tmp |
uniq > $READ_IDS_FILE

rm -f $READ_IDS_FILE.tmp

# log file feedback
head $READ_IDS_FILE
echo "..."
echo `cat $READ_IDS_FILE | wc -l`" unique read ids"
echo
