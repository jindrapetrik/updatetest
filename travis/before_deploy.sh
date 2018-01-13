#!/bin/bash
#stop on error
set -e
git config --local user.name "jindrapetrik"
git config --local user.email "jindra.petrik@gmail.com"
if [ -n "$DEPLOY_CREATE_TAG" ]; then
  git tag "$DEPLOY_CREATE_TAG" 
fi