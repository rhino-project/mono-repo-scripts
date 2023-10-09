#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Full path to the file in the script directory
FIXUP_PATCH="$SCRIPT_DIR/fixups.patch"

rm -rf ./boilerplate_server_rails_mono

git clone git@github.com:nubinary/boilerplate_server.git boilerplate_server_rails_mono

cd ./boilerplate_server_rails_mono
git cob feature/single-repo

cp ../boilerplate_server/.env .

bundle add vite_rails
bundle exec vite install
rm -r node_modules
git add .
git cam "Install vite_rails"

git remote add boilerplate_client ../boilerplate_client
git fetch boilerplate_client

git checkout -b branch_boilerplate_client boilerplate_client/main
mkdir client_files
git mv -k * client_files/
git mv .npmrc client_files/
git mv .nvmrc client_files/
git mv .eslintrc.json client_files/
git mv .prettierrc.json client_files/
git mv .prettierignore client_files/
git mv .istanbul.yml client_files/.istanbul.yml
git rm -r .circleci .devcontainer .dockerignore .editorconfig .gitignore
git cam "Moved boilerplate_client repo to client_files subdir"

git co feature/single-repo
git merge branch_boilerplate_client --allow-unrelated-histories --no-edit

git mv client_files/.npmrc .
git mv client_files/.nvmrc .
git mv client_files/.eslintrc.json .
git mv client_files/.prettierrc.json .
git mv client_files/.prettierignore .
git mv client_files/.istanbul.yml .
git mv -f client_files/vite.config.ts .
git mv -f client_files/package.json .
git mv -f client_files/package-lock.json .
git mv client_files/tsconfig.json app/frontend/
git mv client_files/src app/frontend/
git mv app/frontend/src/index.js app/frontend/entrypoints/index.js
git rm app/frontend/entrypoints/application.js
git commit -m "Moved files to desired locations"

git rm -r client_files
git commit -m "Removed client_files subdirectory"

npm add -D vite-plugin-ruby
npm i

git cam "Add vite-plugin-ruby"

# Extract the value of ROOT_URL
ROOT_URL_VALUE=$(grep "ROOT_URL=" .env | cut -d '=' -f2)
# Replace the value of FRONT_END_URL with the value of ROOT_URL
sed -i '' "s|FRONT_END_URL=.*|FRONT_END_URL=$ROOT_URL_VALUE|" .env

# Create the directory if it doesn't exist
mkdir -p app/views/frontend

# Write the content to the file
cat <<EOL > app/views/frontend/root.html.erb
<noscript>You need to enable JavaScript to run this app.</noscript>
<div id="root"></div>
EOL

echo "Content written to app/views/frontend/root.html.erb"


# Create the directory if it doesn't exist
mkdir -p app/controllers

# Write the content to the file
cat <<EOL > app/controllers/frontend_controller.rb
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

echo "patching $FIXUP_PATCH"
patch -p1 < $FIXUP_PATCH
git cam "Fixup patch"
