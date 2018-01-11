#!/bin/bash
# If we've got website password, we can upload nightly builds.
# Travis secure variable $website_password is not available from outside 
# of jpexs repository (e.g pull requests from other users on GitHub)
if [ -z ${GITHUB_ACCESS_TOKEN+x} ]; then
    # password not set,  just make private release without publishing result
    #...
    echo "no github access token set"
else
    # if we are on the dev branch
    if [ $TRAVIS_BRANCH = "dev" ]; then
        # create nightly build...
                
        TAG_COMMIT_HASH=$TRAVIS_COMMIT
        GITHUB_USER=jindrapetrik
        GITHUB_REPO=$TRAVIS_REPO_SLUG
        RELEASES_JSON=`curl --silent --request GET --header "Accept: application/vnd.github.manifold-preview" https://api.github.com/repos/$GITHUB_REPO/releases`
        LAST_NIGHTLY_VER=`echo releases_json|jq --raw-output '.[].tag_name'|grep 'nightly'|sed 's/nightly//'|head -n 1`
        NEXT_NIGHTLY_VER=$(($LAST_NIGHTLY_VER+1))
        LAST_NIGHTLY_TAG=nightly$LAST_NIGHTLY_VER
        NEXT_NIGHTLY_TAG=nightly$NEXT_NIGHTLY_TAG
        
        #Remove old nightly
        TAG_INFO=`curl --silent https://api.github.com/repos/$GITHUB_REPO/releases/tags/$LAST_NIGHTLY_TAG`
        RELEASE_ID=`echo $TAG_INFO|jq '.id'`
        curl --silent --request DELETE --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/releases/$RELEASE_ID
        
        #Release new nightly
        TAGGER_NAME="Jindra Petøík"
        TAGGER_EMAIL=jindra.petrik@gmail.com
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
        echo '{"tag":"'$TAG_NAME'","message":"","object":"'$TAG_COMMIT_HASH'","type":"commit","tagger":{"name":'$ESC_TAGGER_NAME',"email":"'$TAGGER_EMAIL'","date":"'$CURRENT_DATE'"}}'>json.bin
        curl --silent --request POST --data-binary @json.bin --header "Content-Type: application/json" --header "Accept: application/vnd.github.manifold-preview" --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/git/tags
        #-create release for that tag
        echo '{"tag_name":"'$TAG_NAME'","target_commitish":"master","name":'$ESC_VERSION_NAME',"body":'$ESC_VERSION_DESCRIPTION',"draft":false,"prerelease":'$VERSION_PRERELEASE'}'>json.bin
        curl --silent --request POST --data-binary @json.bin  --header "Content-Type: application/json" --header "Accept: application/vnd.github.manifold-preview" --user $GITHUB_USER:$GITHUB_ACCESS_TOKEN https://api.github.com/repos/$GITHUB_REPO/releases            
        echo "NIGHTLY RELEASED"
    else
        # another branch, just make private release
        #...
        echo "NOT ON dev branch"
    fi
fi