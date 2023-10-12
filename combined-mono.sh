#!/bin/bash

rm -rf ./mono-construction

mkdir -p mono-construction/boilerplate_mono
cd  mono-construction

git clone git@github.com:nubinary/boilerplate_client.git
cd boilerplate_client
git-filter-repo --to-subdirectory-filter client

cd ..

git clone git@github.com:nubinary/boilerplate_server.git
cd boilerplate_server
git-filter-repo --to-subdirectory-filter server

cd ../boilerplate_mono
git init

git remote add boilerplate_client ../boilerplate_client
git fetch boilerplate_client
git merge boilerplate_client/main --allow-unrelated-histories

git remote add boilerplate_server ../boilerplate_server
git fetch boilerplate_server
git merge boilerplate_server/main --allow-unrelated-histories





