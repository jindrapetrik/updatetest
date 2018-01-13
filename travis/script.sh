#!/bin/bash
#stop on error
set -e
# If we've got website password, we can upload nightly builds.
# Travis secure variable $website_password is not available from outside 
# of jpexs repository (e.g pull requests from other users on GitHub)
if [ -z ${GITHUB_ACCESS_TOKEN+x} ]; then
    # password not set,  just make private release without publishing result
    #...
    echo "no github access token set"
else
    # if tag set
    if [ -n "$TRAVIS_TAG" ]; then
      #tag starts with "version" prefix
      if [[ $TRAVIS_TAG =~ ^version.* ]] ; then
        VERSION_NUMBER=`echo $TRAVIS_TAG|sed 's/version//'`
        # release standard version based on tag
        echo "RELEASE standard version"
        export DEPLOY_TAG_NAME=$TRAVIS_TAG
        #TODO: format this:
        export DEPLOY_VERSION_NAME="version $VERSION_NUMBER"
        #and this:
        export DEPLOY_DESCRIPTION="version $VERSION_NUMBER description"
        export DEPLOY_COMMITISH="master"
        export DEPLOY_PRERELEASE=false
        export DO_DEPLOY=1            
      fi
    else
        #if we are on dev branch
        if [ $TRAVIS_BRANCH = "dev" ]; then    
          # create nightly build...
          
          TAGGER_NAME="Travis CI"
          TAGGER_EMAIL=travis@travis-ci.org          
                  
          TAG_COMMIT_HASH=$TRAVIS_COMMIT
          GITHUB_REPO=$TRAVIS_REPO_SLUG
          RELEASES_JSON=`curl --silent --request GET --header "Accept: application/vnd.github.manifold-preview" --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/releases`
          LAST_NIGHTLY_VER=`echo $RELEASES_JSON|jq --raw-output '.[].tag_name'|grep 'nightly'|sed 's/nightly//'|head -n 1`
          NEXT_NIGHTLY_VER=$(($LAST_NIGHTLY_VER+1))
          LAST_NIGHTLY_TAG=nightly$LAST_NIGHTLY_VER
          NEXT_NIGHTLY_TAG=nightly$NEXT_NIGHTLY_VER
          
          #Release new nightly
          VERSION_NAME="nightly $NEXT_NIGHTLY_VER"
          VERSION_DESCRIPTION="Nightly version $NEXT_NIGHTLY_VER with some changes"
          VERSION_PRERELEASE=true
          CURRENT_DATE=`date +%Y-%m-%dT%H:%M:%SZ`
  
          ESC_VERSION_NAME=`echo $VERSION_NAME|jq --raw-input --ascii-output '.'`
          ESC_VERSION_DESCRIPTION=`echo $VERSION_DESCRIPTION|jq --raw-input --ascii-output '.'`
          ESC_TAGGER_NAME=`echo $TAGGER_NAME|jq --raw-input --ascii-output '.'`        
          TAG_NAME=$NEXT_NIGHTLY_TAG
          VERSION_PRERELEASE=true
                  
          #-create tag
          echo "Creating tag $TAG_NAME..."
          echo '{"tag":"'$TAG_NAME'","message":"","object":"'$TAG_COMMIT_HASH'","type":"commit","tagger":{"name":'$ESC_TAGGER_NAME',"email":"'$TAGGER_EMAIL'","date":"'$CURRENT_DATE'"}}'>json.bin
          curl --silent --request POST --data-binary @json.bin --header "Content-Type: application/json" --header "Accept: application/vnd.github.manifold-preview" --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/git/tags>/dev/null
                    
          export DEPLOY_RELEASE_TO_REMOVE=$LAST_NIGHTLY_TAG                                 
          export DEPLOY_TAG_NAME=$NEXT_NIGHTLY_TAG
          export DEPLOY_VERSION_NAME="nightly $NEXT_NIGHTLY_VER"
          #TODO: format this:
          export DEPLOY_DESCRIPTION="version $DEPLOY_VERSION_NAME description"
          export DEPLOY_COMMITISH="dev"
          export DEPLOY_PRERELEASE=true
          export DO_DEPLOY=1                    
        fi
    fi
fi