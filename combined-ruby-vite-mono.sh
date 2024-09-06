#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

APP_HTML_PATCH="$SCRIPT_DIR/app-html.patch"
VITE_RUBY_PLUGIN_PATCH="$SCRIPT_DIR/vite-ruby-plugin.patch"
ENTRY_POINT_PATCH="$SCRIPT_DIR/entrypoint.patch"
TSCONFIG_PATH_PATCH="$SCRIPT_DIR/tsconfig-path.patch"
CYPRESS_STATIC_PATCH="$SCRIPT_DIR/cypress-static.patch"

DEVCONTAINER_PATCH="$SCRIPT_DIR/devcontainer.patch"
TESTS_PATCH="$SCRIPT_DIR/tests.patch"
FRONTEND_TESTS_PATCH="$SCRIPT_DIR/frontend-tests.patch"

rm -rf ./rhino-project-template_rails_mono

git clone git@github.com:rhino-project/rhino-project-template.git rhino-project-template_rails_mono

cd ./rhino-project-template_rails_mono/server
git checkout feat/pnpm
git checkout -b feature/single-repo

cp ../../../rhino-project-template/server/.env .


CLIENT_DOT_FILES=".npmrc .nvmrc .eslintrc.cjs .prettierrc.json .prettierignore .istanbul.yml"
for file in $CLIENT_DOT_FILES; do
 git mv ../client/$file .
done

# Configuration files
git mv -f ../client/vite.config.ts .
git mv -f ../client/package.json .
git mv -f ../client/pnpm-lock.yaml .
git mv ../client/tsconfig.json .
git mv ../client/tsconfig.node.json .

# Cypress
git mv ../client/tsconfig.cypress.json .
git mv ../client/cypress.config.ts .
git mv ../client/cypress .

git commit -m "Move configuration files"

bundle add vite_rails
bundle exec vite install
git add .
git commit -m "Install vite_rails"

# Core code
rm -rf app/frontend
git mv ../client/src app/frontend
mkdir -p app/frontend/entrypoints
git mv app/frontend/index.jsx app/frontend/entrypoints/application.jsx

git commit -m "Client files"

# Extract the value of ROOT_URL
ROOT_URL_VALUE=$(grep "ROOT_URL=" .env | cut -d '=' -f2)
# Replace the value of FRONT_END_URL with the value of ROOT_URL
sed -i '' "s|FRONT_END_URL=.*|FRONT_END_URL=$ROOT_URL_VALUE|" .env
grep -q "^VITE_API_ROOT_PATH=" .env && \
  sed -i '' "s|^VITE_API_ROOT_PATH=.*|VITE_API_ROOT_PATH=$ROOT_URL_VALUE|" .env || \
  echo "VITE_API_ROOT_PATH=$ROOT_URL_VALUE" >> .env

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
git cam "Add frontend_controller and root view"

# Use sed to make the changes
sed -i '' '/root to: redirect(ENV\["FRONT_END_URL"\] || "\/"), via: :all/d' config/routes.rb
sed -i '' '/ActiveAdmin.routes(self)/a\
\
  constraints lambda { |req| !req.path.starts_with?("/api/") || req.url[/\\/rails\\/active_storage\\//].present? } do\
    match "*path", to: "frontend#root", via: :get\
  end\
  root to: "frontend#root", via: :get' config/routes.rb

git cam "Add frontend#root route"

echo "patching $APP_HTML_PATCH"
patch -p2 < $APP_HTML_PATCH
git cam "Update application.html.erb"

echo "patching $VITE_RUBY_PLUGIN_PATCH"
patch -p2 < $VITE_RUBY_PLUGIN_PATCH
git cam "Add vite ruby plugin"

echo "patching $ENTRY_POINT_PATCH"
patch -p2 < $ENTRY_POINT_PATCH
git cam "Update entrypoint"

echo "patching $TSCONFIG_PATH_PATCH"
patch -p2 < $TSCONFIG_PATH_PATCH
git cam "Update tsconfig paths"

echo app/frontend/models/static.js > .prettierignore
git cam "Ignore static.js in prettier"

echo "patching $CYPRESS_STATIC_PATCH"
patch -p2 < $CYPRESS_STATIC_PATCH
git cam "Update cypress static load"

echo "patching $TESTS_PATCH"
patch -p2 < $TESTS_PATCH
git cam "Tests patch"

# From installation of ruby vite
rm -rf node_modules
rm -rf .bundle

git mv -f * ..
git mv .rubocop.yml ..
git mv .ruby-version ..
git mv .simplecov ..
git mv -f .gitignore ..
git mv -f .dockerignore ..
echo "" >> ../.dockerignore && cat ../client/.dockerignore >> ../.dockerignore

# Already covered at the top
git rm -rf .vscode
git rm .tool-versions

mv .env ..

# Yes, we are moving them twice, but we don't want to rewrite this script
CLIENT_DOT_FILES=".npmrc .nvmrc .eslintrc.cjs .prettierrc.json .prettierignore .istanbul.yml"
for file in $CLIENT_DOT_FILES; do
 git mv $file ..
done

cd ..
rm -rf server

git cam "Move server files to top level"

exit

echo "patching $DEVCONTAINER_PATCH"
patch -p1 < $DEVCONTAINER_PATCH
git cam "Devcontainer patch"

echo "patching $FRONTEND_TESTS_PATCH"
patch -p1 < $FRONTEND_TESTS_PATCH
git add cypress.config.ts
git cam "Frontend tests patch"



## TODO
# Location of source files
# Virtual module paths
# static.js write path in plugin
# Unified docker dev environment
# Unified docker prod environment
# Docker compose updates
# Docker ignore updates
# Devcontainer
# Procfile updates?
# README fixes
# Index.html support (Segment, Stripe)
# Move files to top level

