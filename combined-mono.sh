#!/bin/bash

GIT_REPO_BASE=${1:-boilerplate_}
GIT_REPO_ORG=${2:-nubinary}
CLIENT_REPO_NAME="${GIT_REPO_BASE}client"
SERVER_REPO_NAME="${GIT_REPO_BASE}server"
MONO_REPO_NAME="${GIT_REPO_BASE}mono"

#rm -rf ./mono-construction

mkdir -p "mono-construction/${MONO_REPO_NAME}"
cd  mono-construction

git clone "git@github.com:${GIT_REPO_ORG}/${CLIENT_REPO_NAME}.git"
cd $CLIENT_REPO_NAME
git-filter-repo --to-subdirectory-filter client

cd ..

git clone "git@github.com:${GIT_REPO_ORG}/${SERVER_REPO_NAME}.git"
cd $SERVER_REPO_NAME
git-filter-repo --to-subdirectory-filter server

cd ../$MONO_REPO_NAME
git init

git remote add $CLIENT_REPO_NAME ../$CLIENT_REPO_NAME
git fetch $CLIENT_REPO_NAME
git merge $CLIENT_REPO_NAME/main --allow-unrelated-histories

git remote add $SERVER_REPO_NAME ../$SERVER_REPO_NAME
git fetch $SERVER_REPO_NAME
git merge $SERVER_REPO_NAME/main --allow-unrelated-histories --no-edit





