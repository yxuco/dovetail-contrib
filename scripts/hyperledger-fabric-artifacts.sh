#!/bin/bash
build_tag=$1
if [ -d .target/hyperledger-fabric ]; then
  rm -rf .target/hyperledger-fabric
fi
mkdir -p .target/hyperledger-fabric

cd hyperledger-fabric

echo "Building fabric extension"
zip -r ../.target/hyperledger-fabric/fabric-extension-${build_tag////-}.zip fabric

echo "Building fabric general extension"
zip -r ../.target/hyperledger-fabric/fabric-general-extension-${build_tag////-}.zip general

echo "Building fabric client extension"
zip -r ../.target/hyperledger-fabric/fabric-client-extension-${build_tag////-}.zip fabclient

echo "Building fabric functions"
zip -r ../.target/hyperledger-fabric/fabric-function-${build_tag////-}.zip function