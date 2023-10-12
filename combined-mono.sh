#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

FIXUP_PATCH="$SCRIPT_DIR/fixups.patch"
DEVCONTAINER_PATCH="$SCRIPT_DIR/devcontainer.patch"
TESTS_PATCH="$SCRIPT_DIR/tests.patch"
FRONTEND_TESTS_PATCH="$SCRIPT_DIR/frontend-tests.patch"

rm -rf ./boilerplate_mono

mkdir boilerplate_mono
cd boilerplate_mono
git init

cp ../boilerplate_server/.env .

git remote add boilerplate_server ../boilerplate_server
git fetch boilerplate_server
git checkout -b branch_boilerplate_server boilerplate_server/main
mkdir server
git mv -k * server/
git cam "Moved boilerplate_server repo to server subdir"
git checkout main
git merge branch_boilerplate_server --allow-unrelated-histories

git remote add boilerplate_client ../boilerplate_client
git fetch boilerplate_client
git checkout -b branch_boilerplate_client boilerplate_client/main
mkdir client
git mv -k * client/
git mv .circleci/config.yml .devcontainer/devcontainer.json .dockerignore .gitignore client/

git cam "Moved boilerplate_client repo to client subdir"
git checkout main
git merge branch_boilerplate_client --allow-unrelated-histories



