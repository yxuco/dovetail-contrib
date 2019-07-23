#!/bin/bash

IMAGE_NAME=$1
IMAGE_TAG=$2
IMAGE_URL=$3
echo "IMAGE_NAME ${IMAGE_NAME}..."
echo "creating temp directory ..."
temp_dir=$(mktemp -d)
echo "created temp directory $temp_dir"
echo "Removing /var/lib/wi/wi-contrib.git..."
rm -rf /var/lib/wi/wi-contrib.git
mkdir -p /var/lib/wi/wi-contrib.git
echo "Copying function content to tempdir ..."
cp -r "function" $temp_dir
echo "Copying activity content to tempdir ..."
cp -r "SmartContract/activity" $temp_dir
cp Dockerfile $temp_dir
cd $temp_dir
echo "Building ${IMAGE_NAME}:${IMAGE_TAG} ..."
docker build -t ${IMAGE_NAME} .
docker tag ${IMAGE_NAME} ${IMAGE_URL}/${IMAGE_NAME}:${IMAGE_TAG}
docker push ${IMAGE_URL}/${IMAGE_NAME}:${IMAGE_TAG}

echo "cleaning up..."
rm -Rf ${temp_dir}