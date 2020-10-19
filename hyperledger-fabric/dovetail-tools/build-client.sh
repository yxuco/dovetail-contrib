#!/bin/bash
# Copyright © 2018. TIBCO Software Inc.
#
# This file is subject to the license terms contained
# in the license file that is distributed with this file.

# run this script in dovetail-tools docker container to build executables for fabric client
# usage;
#   build-client.sh <model> <name> <GOOS> <GOARCH>

MODEL=${1}
NAME=${2}
TOS=${3}
TARCH=${4}
echo "build-client.sh ${MODEL} ${NAME} ${TOS} ${TARCH}"
env

function create {
  local modelFile=${MODEL##*/}
  local modelDir=${MODEL%/*}

  if [ -d "/tmp/${NAME}" ]; then
    echo "cleanup old workspace /tmp/${NAME}"
    rm -rf /tmp/${NAME}
  fi
  mkdir -p /tmp/${NAME}
  cp ${MODEL} /tmp/${NAME}
  cd /tmp/${NAME}
  flogo create --cv ${FLOGO_VER} -f ${modelFile} ${NAME}

  cd /tmp/${NAME}/${NAME}
  ./codegen.sh ${FE_HOME}
  cd src
  chmod +x gomodedit.sh
  ./gomodedit.sh
}

function build {
  cd /tmp/${NAME}/${NAME}/src
  go mod edit -replace=github.com/project-flogo/core=${FLOGO_REPO}/core@${FLOGO_REPO_VER}
  go mod edit -replace=github.com/project-flogo/flow=${FLOGO_REPO}/flow@${FLOGO_REPO_VER}
  cd ..
  flogo build -e --verbose
  cd src
  go mod vendor
  GOOS=${TOS} GOARCH=${TARCH} go build -mod vendor -o ${WORK}/${NAME}_${TOS}_${TARCH}
  echo "client executable: ${WORK}/${NAME}_${TOS}_${TARCH}"
}

create
build
