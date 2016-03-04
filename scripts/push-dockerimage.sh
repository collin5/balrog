#!/bin/bash

set -e

password_url="taskcluster/secrets/v1/secret/repo:github.com/mozilla/balrog:dockerhub"
dockerhub_email=release+balrog@mozilla.com
dockerhub_username=mozillabalrog
dockerhub_password=$(curl ${password_url} | python -c 'import json, sys; a = json.load(sys.stdin); print a["secret"]["dockerhub_password"]')

if [ -z $dockerhub_password ]; then
    echo "Dockerhub password not set, can't continue!"
    exit 1
fi

commit=$(git rev-parse HEAD)
version=$(cat version.txt)
branch=$(git rev-parse --abbrev-ref HEAD)

echo "{
    \"commit\": \"${commit}\",
    \"version\": \"${version}\",
    \"source\": \"https://github.com/mozilla/balrog\"
}" > version.json

# TODO: We probably should build this for other branches at some point, maybe as
# mozilla/balrog:$branch ?
image_tag="${branch}"
if [ "$branch" == "master" ]; then
    image_tag = "latest"
fi
docker build -t mozilla/balrog:${image_tag} .
docker login -e $dockerhub_email -u $dockerhub_username -p $dockerhub_password
docker push mozilla/balrog:${image_tag}
