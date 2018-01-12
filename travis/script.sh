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
    # if no tag set
    if [ -z ${TRAVIS_TAG+x} ]; then
        #if we are on dev branch
        if [ $TRAVIS_BRANCH = "dev" ]; then    
          # create nightly build...
                  
          TAG_COMMIT_HASH=$TRAVIS_COMMIT
          GITHUB_REPO=$TRAVIS_REPO_SLUG
          RELEASES_JSON=`curl --silent --request GET --header "Accept: application/vnd.github.manifold-preview" --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/releases`
          LAST_NIGHTLY_VER=`echo $RELEASES_JSON|jq --raw-output '.[].tag_name'|grep 'nightly'|sed 's/nightly//'|head -n 1`
          NEXT_NIGHTLY_VER=$(($LAST_NIGHTLY_VER+1))
          LAST_NIGHTLY_TAG=nightly$LAST_NIGHTLY_VER
          NEXT_NIGHTLY_TAG=nightly$NEXT_NIGHTLY_VER
          
          #Release new nightly
          TAGGER_NAME="Travis CI"
          TAGGER_EMAIL=travis@travis-ci.org
          VERSION_NAME="nightly $NEXT_NIGHTLY_VER"
          VERSION_DESCRIPTION="Nightly version $NEXT_NIGHTLY_VER with some changes"
          VERSION_PRERELEASE=true
          CURRENT_DATE=`date +%Y-%m-%dT%H:%M:%SZ`
  
          ESC_VERSION_NAME=`echo $VERSION_NAME|jq --raw-input --ascii-output '.'`
          ESC_VERSION_DESCRIPTION=`echo $VERSION_DESCRIPTION|jq --raw-input --ascii-output '.'`
          ESC_TAGGER_NAME=`echo $TAGGER_NAME|jq --raw-input --ascii-output '.'`        
          TAG_NAME=$NEXT_NIGHTLY_TAG
          VERSION_PRERELEASE=true
          echo TAG_NAME=$TAG_NAME
                  
          #-create tag
          echo "Creating tag..."
          echo '{"tag":"'$TAG_NAME'","message":"","object":"'$TAG_COMMIT_HASH'","type":"commit","tagger":{"name":'$ESC_TAGGER_NAME',"email":"'$TAGGER_EMAIL'","date":"'$CURRENT_DATE'"}}'>json.bin
          curl --silent --request POST --data-binary @json.bin --header "Content-Type: application/json" --header "Accept: application/vnd.github.manifold-preview" --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/git/tags>/dev/null
          #-create release for that tag
          echo "Creating release..."
          echo '{"tag_name":"'$TAG_NAME'","target_commitish":"master","name":'$ESC_VERSION_NAME',"body":'$ESC_VERSION_DESCRIPTION',"draft":false,"prerelease":'$VERSION_PRERELEASE'}'>json.bin
          curl --silent --request POST --data-binary @json.bin  --header "Content-Type: application/json" --header "Accept: application/vnd.github.manifold-preview" --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/releases>/dev/null            
          echo "NIGHTLY RELEASED"
          
          #Remove old nightly
          echo "Removing old nightly..."
          #-remove release
          TAG_INFO=`curl --silent --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/releases/tags/$LAST_NIGHTLY_TAG`
          RELEASE_ID=`echo $TAG_INFO|jq '.id'`
          curl --silent --request DELETE --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/releases/$RELEASE_ID >/dev/null
          #-delete tag
          git config --global user.email "$TAGGER_EMAIL"
          git config --global user.name "$TAGGER_NAME"
          git tag -d $LAST_NIGHTLY_TAG
          git remote add myorigin https://${GITHUB_ACCESS_TOKEN}@github.com/$TRAVIS_REPO_SLUG.git > /dev/null 2>&1
          git push --quiet myorigin :refs/tags/$LAST_NIGHTLY_TAG > /dev/null 2>&1
      
          
          #set travis tag for deploying
          TRAVIS_TAG=$TAG_NAME
          echo "FINISHED"
        fi
    else #if tag is set
        #release version
        echo "RELEASE standard version"        
    fi
fi