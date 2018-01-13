#!/bin/bash
#stop on error
set -e
git config --local user.name "jindrapetrik"
git config --local user.email "jindra.petrik@gmail.com"
CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
echo CURRENT_BRANCH=$CURRENT_BRANCH
 
if [ -n "$DEPLOY_CREATE_TAG" ]; then
  echo DEPLOY_CREATE_TAG=$DEPLOY_CREATE_TAG
  git tag "$DEPLOY_CREATE_TAG" 
fi