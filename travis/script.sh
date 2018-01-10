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
        # create nightly build
        #...
        echo "CREATE NIGHTLY"
    else
        # another branch, just make private release
        #...
        echo "NOT ON dev branch"
    fi
fi