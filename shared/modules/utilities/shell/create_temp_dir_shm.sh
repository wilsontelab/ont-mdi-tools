# action:
#     create a temporary directory in shared memory
# uses:
#     /dev/shm
# sets:
#     $TMP_DIR_WRK_SHM
#     $TMP_FILE_PREFIX_SHM
# creates:
#     $TMP_DIR_WRK_SHM

export TMP_DIR_WRK_SHM=/dev/shm/$SUITE_NAME.$PIPELINE_NAME.$PIPELINE_ACTION/$DATA_NAME
export TMP_FILE_PREFIX_SHM=$TMP_DIR_WRK_SHM/$DATA_NAME
mkdir -p $TMP_DIR_WRK_SHM
trap "rm -rf $TMP_DIR_WRK_SHM" EXIT # makes sure we clean up the tmp dir however script exits
