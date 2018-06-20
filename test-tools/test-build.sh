#!/bin/bash

# Usage: script/test-build.sh PATH_TO_GIT_REPO BUILD_COMMAND
#
# Example with clean git clone:
# 	./test-build.sh ../netlify-cms 'npm run build'
#
# Example with previous cached build:
#	T=/tmp/cache script/test-build.sh ../netlify-cms 'npm run build'

if [ $NETLIFY_VERBOSE ]
then
  set -x
fi

set -e

: ${NETLIFY_IMAGE="netlify/build"}
: ${NODE_VERSION="8"}
: ${RUBY_VERSION="2.3.6"}
: ${YARN_VERSION="1.3.2"}
: ${NPM_VERSION=""}
: ${HUGO_VERSION="0.20"}
: ${PHP_VERSION="5.6"}
: ${GO_VERSION="1.10"}

REPO_URL=$1
PROJECT_NAME=`echo $1 | rev | cut -d'/' -f1 | rev`


REPO_URL=$1
PROJECT_NAME=`echo $1 | rev | cut -d'/' -f1 | rev`
BUILD_DIR=~/build/${PROJECT_NAME}
T=$BUILD_DIR

mkdir -p $BUILD_DIR

DOCKER_GROUP_ID=2500
sudo chown $DOCKER_GROUP_ID $BUILD_DIR
sudo chmod g+w $BUILD_DIR
sudo setfacl -m default:group:$(id -g):rwx $BUILD_DIR
sudo setfacl -m default:user:$DOCKER_GROUP_ID:rwx $BUILD_DIR

echo "Using temp dir: $T"
chmod +w $T
mkdir -p $T/scripts
mkdir -p $T/cache
chmod a+w $T/cache

cp run-build* $T/scripts
chmod +x $T/scripts/*

[[ ! -d $T/repo ]] && git clone $REPO_URL $T/repo

SCRIPT="/opt/buildhome/scripts/run-build.sh $2"

docker run --rm \
       -e "NODE_VERSION=$NODE_VERSION" \
       -e "RUBY_VERSION=$RUBY_VERSION" \
       -e "YARN_VERSION=$YARN_VERSION" \
       -e "NPM_VERSION=$NPM_VERSION" \
       -e "HUGO_VERSION=$HUGO_VERSION" \
       -e "PHP_VERSION=$PHP_VERSION" \
       -e "NETLIFY_VERBOSE=$NETLIFY_VERBOSE" \
       -e "GO_VERSION=$GO_VERSION" \
       -e "GO_IMPORT_PATH=$GO_IMPORT_PATH" \
       -v $BUILD_DIR/scripts:/opt/buildhome/scripts \
       -v $BUILD_DIR/repo:/opt/buildhome/repo \
       -v $BUILD_DIR/cache:/opt/buildhome/cache \
       -w /opt/build \
       -it \
       $NETLIFY_IMAGE $SCRIPT
