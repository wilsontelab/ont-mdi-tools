#!/bin/bash

if [ ! -d ${DORADO_VERSION_DIR} ]; then
    echo "downloading Dorado version "${DORADO_VERSION}
    cd ${DORADO_DIR}
    DORADO_ARCHIVE=${DORADO_VERSION_NAME}".tar.gz"
    wget "https://cdn.oxfordnanoportal.com/software/analysis/"${DORADO_ARCHIVE}
    tar -xzf ${DORADO_ARCHIVE}
    rm -f ${DORADO_ARCHIVE}
else
    echo "Dorado version "${DORADO_VERSION}" already present"
fi

if [ ! -e ${ONT_MODEL_DIR} ]; then
    echo "downloading ONT model "${ONT_MODEL}
    cd ${ONT_MODELS_DIR}
    ${DORADO_EXECUTABLE} download --model ${ONT_MODEL}
else
    echo "ONT model "${ONT_MODEL}" already present"
fi

echo "done"
