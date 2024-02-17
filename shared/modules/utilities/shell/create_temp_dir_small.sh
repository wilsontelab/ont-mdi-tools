# action:
#     create a temporary directory for smaller (i.e., moderate size) data files
# uses:
#     $TMP_DIR
# sets:
#     $TMP_DIR_WRK_SMALL
#     $TMP_FILE_PREFIX_SMALL
# creates:
#     $TMP_DIR_WRK_SMALL

export TMP_DIR_WRK_SMALL=$TMP_DIR/$SUITE_NAME.$PIPELINE_NAME.$PIPELINE_ACTION/$DATA_NAME
export TMP_FILE_PREFIX_SMALL=$TMP_DIR_WRK_SMALL/$DATA_NAME
mkdir -p $TMP_DIR_WRK_SMALL
trap "rm -rf $TMP_DIR_WRK_SMALL" EXIT # makes sure we clean up the tmp dir however script exits
