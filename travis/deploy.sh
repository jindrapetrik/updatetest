#!/bin/bash
#stop on error
set -e

GITHUB_REPO=$TRAVIS_REPO_SLUG

echo "Creating release..."
ESC_VERSION_NAME=`echo $DEPLOY_VERSION_NAME|jq --raw-input --ascii-output '.'`
ESC_VERSION_DESCRIPTION=`echo $DEPLOY_DESCRIPTION|jq --raw-input --ascii-output '.'`
          
echo '{"tag_name":"'$DEPLOY_TAG_NAME'","target_commitish":"$DEPLOY_COMMITISH","name":'$ESC_VERSION_NAME',"body":'$ESC_VERSION_DESCRIPTION',"draft":false,"prerelease":'$DEPLOY_PRERELEASE'}'>json.bin
curl --silent --request POST --data-binary @json.bin  --header "Content-Type: application/json" --header "Accept: application/vnd.github.manifold-preview" --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/releases>/dev/null            
          

if [ -n "$DEPLOY_RELEASE_TO_REMOVE" ]; then
  git config --local user.email "travis@travis-ci.org"
  git config --local user.name "Travis CI"          
  #Remove old nightly
  echo "Removing old release..."
  #-remove release
  TAG_INFO=`curl --silent --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/releases/tags/$DEPLOY_RELEASE_TO_REMOVE`
  RELEASE_ID=`echo $TAG_INFO|jq '.id'`
  curl --silent --request DELETE --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/releases/$RELEASE_ID >/dev/null
  #-delete tag
  git tag -d $DEPLOY_RELEASE_TO_REMOVE
  git push --quiet myorigin :refs/tags/$LAST_NIGHTLY_TAG > /dev/null 2>&1
fi
          