#!/bin/bash

# set derivative environment variables
export SHARED_SUITE=ont-mdi-tools
export SHARED_MODULES_DIR=$SUITES_DIR/$SHARED_SUITE/shared/modules
export SHARED_MODULE_DIR=$SHARED_MODULES_DIR/download

# set the dorado directories
echo "check nanopore directories"
DORADO_DIR=${NANOPORE_DIR}/dorado
mkdir -p ${DORADO_DIR}
DORADO_VERSION_NAME=dorado-${DORADO_VERSION}
DORADO_VERSION_DIR=${DORADO_DIR}/${DORADO_VERSION_NAME}
DORADO_EXECUTABLE=${DORADO_VERSION_DIR}/bin/dorado

# set ONT model paths
ONT_MODELS_DIR=${NANOPORE_DIR}/models
mkdir -p ${ONT_MODELS_DIR}
ONT_MODEL_DIR=${ONT_MODELS_DIR}/${ONT_MODEL}

# download Dorado and the reqested ONT model
runWorkflowStep 1 download $SHARED_MODULE_DIR/download.sh
