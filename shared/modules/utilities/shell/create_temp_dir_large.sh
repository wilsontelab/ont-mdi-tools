# action:
#     create a temporary directory for larger data files too big for TMP_DIR
# uses:
#     $TMP_DIR_LARGE
# sets:
#     $TMP_DIR_WRK_LARGE
#     $TMP_FILE_PREFIX_LARGE
# creates:
#     $TMP_DIR_WRK_LARGE

export TMP_DIR_WRK_LARGE=$TMP_DIR_LARGE/$SUITE_NAME.$PIPELINE_NAME.$PIPELINE_ACTION/$DATA_NAME
export TMP_FILE_PREFIX_LARGE=$TMP_DIR_WRK_LARGE/$DATA_NAME
mkdir -p $TMP_DIR_WRK_LARGE
trap "rm -rf $TMP_DIR_WRK_LARGE" EXIT # makes sure we clean up the tmp dir however script exits
