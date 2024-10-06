#!/bin/bash

GIT_REPO=${1:-rhino-project-template}
GIT_REPO_ORG=${2:-rhino-project}
MONO_REPO_NAME="${GIT_REPO}_rails_mono"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

APP_HTML_PATCH="$SCRIPT_DIR/app-html.patch"
VITE_RUBY_PLUGIN_PATCH="$SCRIPT_DIR/vite-ruby-plugin.patch"
ENTRY_POINT_PATCH="$SCRIPT_DIR/entrypoint.patch"
TSCONFIG_PATH_PATCH="$SCRIPT_DIR/tsconfig-path.patch"
CYPRESS_STATIC_PATCH="$SCRIPT_DIR/cypress-static.patch"
TESTS_PATCH="$SCRIPT_DIR/tests.patch"
FRONTEND_TESTS_PATCH="$SCRIPT_DIR/frontend-tests.patch"
DOCKER_DEV_PATCH="$SCRIPT_DIR/docker-dev.patch"
DOCKER_PATCH="$SCRIPT_DIR/docker.patch"
GHA_PATCH="$SCRIPT_DIR/gha.patch"
ROOT_HTML_PATCH="$SCRIPT_DIR/root_html.patch"
GHA_NIGHTLY_PATCH="$SCRIPT_DIR/gha-nightly.patch"

DEVCONTAINER_PATCH="$SCRIPT_DIR/devcontainer.patch"


rm -rf ${MONO_REPO_NAME}

git clone git@github.com:${GIT_REPO_ORG}/${GIT_REPO}.git ${MONO_REPO_NAME}

cd ${MONO_REPO_NAME}
git checkout -b feature/single-repo

#cp ../../rhino-project-template/server/.env .


CLIENT_DOT_FILES=".npmrc .nvmrc .eslintrc.cjs .prettierrc.json .prettierignore .istanbul.yml"
for file in $CLIENT_DOT_FILES; do
 git mv client/$file .
done

# Configuration files
git mv -f client/vite.config.ts .
git mv -f client/package.json .
git mv -f client/package-lock.json .
git mv client/tsconfig.json .
git mv client/tsconfig.node.json .

# Cypress
git mv client/tsconfig.cypress.json .
git mv client/cypress.config.ts .
git mv client/cypress .

git commit -m "Move configuration files"


git mv -f server/* .
git mv server/.rubocop.yml .
git mv server/.ruby-version .
git mv server/.simplecov .
git mv -f server/.gitignore .
git mv -f server/.dockerignore .
echo "" >> .dockerignore && cat client/.dockerignore >> .dockerignore

# Already covered at the top
git rm -rf server/.vscode
git rm server/.tool-versions

rm -rf server

git commit -am "Move server files to top level"

bundle add vite_rails
bundle exec vite install

# From installation of ruby vite
rm -rf node_modules
rm -rf .bundle

git add .
git commit -m "Install vite_rails"

# Core code
rm -rf app/frontend
git mv client/src app/frontend
mkdir -p app/frontend/entrypoints
git mv app/frontend/index.jsx app/frontend/entrypoints/application.jsx

git commit -m "Client files"

# Extract the value of ROOT_URL
# ROOT_URL_VALUE=$(grep "ROOT_URL=" .env | cut -d '=' -f2)
# # Replace the value of FRONT_END_URL with the value of ROOT_URL
# sed -i '' "s|FRONT_END_URL=.*|FRONT_END_URL=$ROOT_URL_VALUE|" .env
# grep -q "^VITE_API_ROOT_PATH=" .env && \
#   sed -i '' "s|^VITE_API_ROOT_PATH=.*|VITE_API_ROOT_PATH=$ROOT_URL_VALUE|" .env || \
#   echo "VITE_API_ROOT_PATH=$ROOT_URL_VALUE" >> .env

# Create the directory if it doesn't exist
mkdir -p app/views/frontend

# Write the content to the file
cat <<EOL > app/views/frontend/root.html.erb
<noscript>You need to enable JavaScript to run this app.</noscript>
<div id="root" class="h-100"></div>
EOL

echo "Content written to app/views/frontend/root.html.erb"

# Write the content to the file
cat <<EOL > app/controllers/frontend_controller.rb
# frozen_string_literal: true

class FrontendController < ApplicationController
  def root
  end
end
EOL

echo "Content written to app/controllers/frontend_controller.rb"

git add app/controllers/frontend_controller.rb
git add app/views/frontend/root.html.erb
git commit -am "Add frontend_controller and root view"

# Use sed to make the changes
sed -i '' '/root to: redirect(ENV\["FRONT_END_URL"\] || "\/"), via: :all/d' config/routes.rb
sed -i '' '/ActiveAdmin.routes(self)/a\
\
  constraints lambda { |req| !req.path.starts_with?("/api/") || req.url[/\\/rails\\/active_storage\\//].present? } do\
    match "*path", to: "frontend#root", via: :get\
  end\
  root to: "frontend#root", via: :get' config/routes.rb

git commit -am "Add frontend#root route"

echo "patching $APP_HTML_PATCH"
patch -p2 < $APP_HTML_PATCH
git commit -am "Update application.html.erb"

echo "patching $VITE_RUBY_PLUGIN_PATCH"
patch -p2 < $VITE_RUBY_PLUGIN_PATCH
git commit -am "Add vite ruby plugin"

echo "patching $ENTRY_POINT_PATCH"
patch -p2 < $ENTRY_POINT_PATCH
git commit -am "Update entrypoint"

echo "patching $TSCONFIG_PATH_PATCH"
patch -p2 < $TSCONFIG_PATH_PATCH
git commit -am "Update tsconfig paths"

echo app/frontend/models/static.js > .prettierignore
git commit -am "Ignore static.js in prettier"

echo "patching $CYPRESS_STATIC_PATCH"
patch -p2 < $CYPRESS_STATIC_PATCH
git commit -am "Update cypress static load"

echo "patching $TESTS_PATCH"
patch -p2 < $TESTS_PATCH

echo "patching $FRONTEND_TESTS_PATCH"
patch -p1 < $FRONTEND_TESTS_PATCH
git commit -am "Frontend tests patch"

echo "patching $DOCKER_DEV_PATCH"
patch -p1 < $DOCKER_DEV_PATCH
git rm -f docker-compose.yml
git rm -f client-override.yml
git add ./bin/dev-vite-entrypoint.sh
chmod +x ./bin/dev-vite-entrypoint.sh
git commit -am "Docker dev patch"

echo "patching $DOCKER_PATCH"
patch -p1 < $DOCKER_PATCH
git commit -am "Docker patch"

echo "patching $GHA_PATCH"
patch -p1 < $GHA_PATCH
git commit -am "Github actions patch"

echo "patching $ROOT_HTML_PATCH"
patch -p1 < $ROOT_HTML_PATCH
git commit -am "Root html patch"

echo "patching $GHA_NIGHTLY_PATCH"
patch -p1 < $GHA_NIGHTLY_PATCH
git commit -am "GHA nightly patch"

git rm -rf client
git  commit -am "Remove client"

git rm -rf mono.code-workspace
git  commit -am "Remove mono.code-workspace"

exit

echo "patching $DEVCONTAINER_PATCH"
patch -p1 < $DEVCONTAINER_PATCH
git commit -am "Devcontainer patch"

## TODO
# Devcontainer
# README fixes

## DONE
# Location of source files
# Virtual module paths
# Move files to top level
# Fix assets
# Docker ignore updates
# static.js write path in plugin
# Unified docker dev environment
# Docker compose updates
# Github actions
# Procfile updates?
# Index.html support (Segment, Stripe)


