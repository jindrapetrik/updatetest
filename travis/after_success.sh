#!/bin/bash
#stop on error
set -e

if [ "$DO_DEPLOY" = 1 ]; then
  echo "Deploying..."
  GITHUB_REPO=$TRAVIS_REPO_SLUG
  
  echo "Creating release..."
  ESC_VERSION_NAME=`echo $DEPLOY_VERSION_NAME|jq --raw-input --ascii-output '.'`
  ESC_VERSION_DESCRIPTION=`printf "$DEPLOY_DESCRIPTION"|jq --raw-input --slurp --ascii-output '.'`
            
  echo '{"tag_name":"'$DEPLOY_TAG_NAME'","target_commitish":"'$DEPLOY_COMMITISH'","name":'$ESC_VERSION_NAME',"body":'$ESC_VERSION_DESCRIPTION',"draft":false,"prerelease":'$DEPLOY_PRERELEASE'}'>json.bin
  json=`curl --silent --request POST --data-binary @json.bin --header "Content-Type: application/json" --header "Accept: application/vnd.github.manifold-preview" --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/releases`
  RELEASE_ID=`echo "$json"|jq '.id'`
  
  
  
  #List of files to upload
  DEPLOY_ATTACH_FILES_JSON='[
{"file_name":"myfile.txt","file_path":"myfile.txt","content_type":"text/plain"},
{"file_name":"smiley.png","file_path":"smiley.png","content_type":"image/png"}
]';



  #Attaching files...
  NUM_FILES=`echo "$DEPLOY_ATTACH_FILES_JSON"|jq ".|length"`
  
  for (( i=0; i<$NUM_FILES; i++ ))
  do              
    ITEM_JSON=`echo "$DEPLOY_ATTACH_FILES_JSON"|jq '.['$i']'`                                  
    CONTENT_TYPE=`echo "$ITEM_JSON"|jq --raw-output '.content_type'`
    FILE_NAME=`echo "$ITEM_JSON"|jq --raw-output '.file_name'`
    FILE_PATH=`echo "$ITEM_JSON"|jq --raw-output '.file_path'`
    
    curl --silent --request POST --data-binary @$FILE_PATH --header "Content-Type: $CONTENT_TYPE" --header "Accept: application/vnd.github.manifold-preview" --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://uploads.github.com/repos/$GITHUB_REPO/releases/$RELEASE_ID/assets?name=$FILE_NAME
  done
        
  if [ -n "$DEPLOY_RELEASE_TO_REMOVE" ]; then
    #Remove old nightly
    echo "Removing old release $DEPLOY_RELEASE_TO_REMOVE..."
    #-remove release
    TAG_INFO=`curl --silent --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/releases/tags/$DEPLOY_RELEASE_TO_REMOVE`
    RELEASE_ID=`echo $TAG_INFO|jq '.id'`
    curl --silent --request DELETE --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/releases/$RELEASE_ID>/dev/null
    #-delete tag
    git config --local user.email "travis@travis-ci.org"
    git config --local user.name "Travis CI"
    git remote add myorigin https://${GITHUB_ACCESS_TOKEN}@github.com/$TRAVIS_REPO_SLUG.git > /dev/null 2>&1
    git tag -d $DEPLOY_RELEASE_TO_REMOVE
    git push --quiet myorigin :refs/tags/$DEPLOY_RELEASE_TO_REMOVE > /dev/null 2>&1        
  fi  
fi
         