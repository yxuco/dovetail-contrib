#!/bin/bash
# Copyright © 2018. TIBCO Software Inc.
#
# This file is subject to the license terms contained
# in the license file that is distributed with this file.

# run this script in dovetail-tools docker container to build chaincode cds package
# usage;
#   build-cds.sh <model> <cc-name> <cc-version>

FLOGO_VER=v1.1.0
FE_HOME=${HOME}/work/dovetail/flogo210/2.10
SHIM_PATH=${HOME}/work/dovetail/dovetail-contrib/hyperledger-fabric/shim
PATCH_PATH=${HOME}/work/dovetail/dovetail-contrib/hyperledger-fabric/flogo-patch
WORK=${HOME}/work/dovetail/dovetail-contrib/hyperledger-fabric/samples/marble
FAB_PATH=${HOME}/work/dovetail/fabric-samples

MODEL=${1:-"${WORK}/marble.json"}
NAME=${2:-"marble_cc"}
VERSION=${3-"1.0"}
echo "build-cds.sh ${MODEL} ${NAME} ${VERSION}"
# env

function create {
  local modelFile=${MODEL##*/}
  local modelDir=${MODEL%/*}

  if [ -d "/tmp/${NAME}" ]; then
    echo "cleanup old workspace /tmp/${NAME}"
    rm -rf /tmp/${NAME}
  fi
  mkdir /tmp/${NAME}
  cp ${MODEL} /tmp/${NAME}
  cd /tmp/${NAME}
  flogo create --cv ${FLOGO_VER} --verbose -f ${modelFile} ${NAME}
  rm ${NAME}/src/main.go
  cp ${SHIM_PATH}/chaincode_shim.go ${NAME}/src/main.go

  cd ${HOME}
  if [ -d "${modelDir}/META-INF" ]; then
    cp -rf ${modelDir}/META-INF /tmp/${NAME}/${NAME}/src
  fi

  if [ -d "${FE_HOME}" ]; then
    cp ${PATCH_PATH}/codegen.sh /tmp/${NAME}/${NAME}
    cd /tmp/${NAME}/${NAME}
    ./codegen.sh ${FE_HOME}
    cd src
    chmod +x gomodedit.sh
    ./gomodedit.sh
  fi
}

function build {
  cd /tmp/${NAME}/${NAME}/src
  go mod edit -replace=github.com/project-flogo/core=/Users/yxu/go/src/github.com/project-flogo/core
  go mod edit -replace=github.com/project-flogo/flow=/Users/yxu/go/src/github.com/project-flogo/flow
  go mod edit -replace=github.com/TIBCOSoftware/dovetail-contrib/hyperledger-fabric/fabric/common=/Users/yxu/work/dovetail/dovetail-contrib/hyperledger-fabric/fabric/common
  go mod edit -replace=github.com/TIBCOSoftware/dovetail-contrib/hyperledger-fabric/fabric/activity/delete=/Users/yxu/work/dovetail/dovetail-contrib/hyperledger-fabric/fabric/activity/delete
  go mod edit -replace=github.com/TIBCOSoftware/dovetail-contrib/hyperledger-fabric/fabric/activity/get=/Users/yxu/work/dovetail/dovetail-contrib/hyperledger-fabric/fabric/activity/get
  go mod edit -replace=github.com/TIBCOSoftware/dovetail-contrib/hyperledger-fabric/fabric/activity/getbycompositekey=/Users/yxu/work/dovetail/dovetail-contrib/hyperledger-fabric/fabric/activity/getbycompositekey
  go mod edit -replace=github.com/TIBCOSoftware/dovetail-contrib/hyperledger-fabric/fabric/activity/gethistory=/Users/yxu/work/dovetail/dovetail-contrib/hyperledger-fabric/fabric/activity/gethistory
  go mod edit -replace=github.com/TIBCOSoftware/dovetail-contrib/hyperledger-fabric/fabric/activity/getrange=/Users/yxu/work/dovetail/dovetail-contrib/hyperledger-fabric/fabric/activity/getrange
  go mod edit -replace=github.com/TIBCOSoftware/dovetail-contrib/hyperledger-fabric/fabric/activity/put=/Users/yxu/work/dovetail/dovetail-contrib/hyperledger-fabric/fabric/activity/put
  go mod edit -replace=github.com/TIBCOSoftware/dovetail-contrib/hyperledger-fabric/fabric/activity/putall=/Users/yxu/work/dovetail/dovetail-contrib/hyperledger-fabric/fabric/activity/putall
  go mod edit -replace=github.com/TIBCOSoftware/dovetail-contrib/hyperledger-fabric/fabric/activity/query=/Users/yxu/work/dovetail/dovetail-contrib/hyperledger-fabric/fabric/activity/query
  go mod edit -replace=github.com/TIBCOSoftware/dovetail-contrib/hyperledger-fabric/fabric/trigger/transaction=/Users/yxu/work/dovetail/dovetail-contrib/hyperledger-fabric/fabric/trigger/transaction
#  go mod edit -replace=github.com/project-flogo/flow/activity/subflow@v0.9.0=github.com/project-flogo/flow/activity/subflow@master
  cd ..
  flogo build -e --verbose
  cd src
  go mod vendor
#  cp -R ${PATCH_PATH}/* vendor/github.com/project-flogo
  go build -mod vendor -o ../${NAME}_linux_amd64
  if [ ! -f "../${NAME}_linux_amd64" ]; then
    echo "failed to build chaincode"
    exit 1
  fi

  echo "build chaincode cds package ..."
  cd ${HOME}
  if [ -d "${GOPATH}/src/github.com/chaincode/${NAME}" ]; then
    echo "cleanup old chaincode ${NAME}"
    rm -rf ${GOPATH}/src/github.com/chaincode/${NAME}
  fi
  mkdir -p ${GOPATH}/src/github.com/chaincode
  cp -Rf /tmp/${NAME}/${NAME}/src ${GOPATH}/src/github.com/chaincode/${NAME}
  fabric-tools package -n ${NAME} -v ${VERSION} -p ${GOPATH}/src/github.com/chaincode/${NAME} -o ${WORK}/${NAME}_${VERSION}.cds
  chmod +r ${WORK}/${NAME}_${VERSION}.cds
  echo "chaincode cds package: ${WORK}/${NAME}_${VERSION}.cds"
}

function deploy {
  mkdir -p ${FAB_PATH}/chaincode/${NAME}
  cp ${WORK}/${NAME}_${VERSION}.cds ${FAB_PATH}/chaincode/${NAME}
  echo "cp ${WORK}/${NAME}_${VERSION}.cds ${FAB_PATH}/chaincode/${NAME}"
  cp ${WORK}/fn-cli-init.sh ${FAB_PATH}/first-network/scripts/fn-init-marble.sh
  cp ${WORK}/fn-cli-test.sh ${FAB_PATH}/first-network/scripts/fn-test-marble.sh
  echo "copy scripts to ${FAB_PATH}/first-network/scripts"
}

create
build
deploy
