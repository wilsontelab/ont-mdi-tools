# this script is MDI-specific
# it converts MDI Dorado option into forms suitable for use by basecall.sh

# set the dorado directories
echo "checking nanopore directories"
DORADO_DIR=${NANOPORE_DIR}/dorado
DORADO_VERSION_NAME=dorado-${DORADO_VERSION}
DORADO_VERSION_DIR=${DORADO_DIR}/${DORADO_VERSION_NAME}
DORADO_EXECUTABLE=${DORADO_VERSION_DIR}/bin/dorado
if [ ! -f ${DORADO_EXECUTABLE} ]; then
    echo "missing Dorado executable: "${DORADO_EXECUTABLE}
    echo "please use the download action to obtain it"
    exit 1
fi 

# set ONT model paths
echo "checking ONT models"
ONT_MODELS_DIR=${NANOPORE_DIR}/models
ONT_MODEL_DIR=${ONT_MODELS_DIR}/${ONT_MODEL}
if [ ! -d ${ONT_MODEL_DIR} ]; then
    echo "missing ONT model: "${ONT_MODEL_DIR}
    echo "please check your spelling and/or use the download action to obtain it"
    exit 1
fi 
if [ "$MODIFIED_BASE_MODEL" != "NA" ]; then
    MOD_MODEL_DIR=${ONT_MODELS_DIR}/${MODIFIED_BASE_MODEL}
    if [ ! -d ${MOD_MODEL_DIR} ]; then
        echo "missing ONT model: "${MOD_MODEL_DIR}
        echo "please check your spelling and/or use the download action to obtain it"
        exit 1
    fi 
fi

# process and set input and output paths
echo "setting output type"
EXPANDED_INPUT_DIR=`echo ${INPUT_DIR}`
if [[ "$ALIGN_READS" != "" && "$ALIGN_READS" != "0" ]]; then
    BAM_DIR=${TASK_DIR}/bam
else 
    BAM_DIR=${TASK_DIR}/ubam
fi
if [ "$DORADO_OUTPUT_TYPE" != "" ]; then
    BAM_DIR=${BAM_DIR}/${DORADO_OUTPUT_TYPE}
fi

# set basecalling options
READ_IDS_FILE=""
if [ "$DORADO_READ_IDS" != "" ]; then # read ids file cannot be gzipped 
    echo "checking read ids"
    if [ -f $DORADO_READ_IDS ]; then
        READ_IDS_FILE=`echo $DORADO_READ_IDS`
    else 
        READ_IDS_FILE=`echo ${DATA_FILE_PREFIX}.${GENOME}.*.qNames.txt`
    fi
    if [[ "$READ_IDS_FILE" == "" || ! -e $READ_IDS_FILE ]]; then
        echo "requested read ids file not found: $DORADO_READ_IDS"
        exit 1
    fi
fi
