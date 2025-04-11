#!/bin/bash

set -vex
[ -n "${WEB_SITE_BUCKET}" ] || exit 1
[ -n "${CUSTOM_CODEBUILD_GIT_BRANCH_CLEAN}" ] || exit 1
[ -n "${CLOUDFRONT_DISTRO_ID}" ] || exit 1

set +vx

if [ "$CUSTOM_CODEBUILD_GIT_PR" != '' ] ; then
  export DEPLOY_DIR="temp/prs/${CUSTOM_CODEBUILD_GIT_PR}";
else
  if [ "$CUSTOM_CODEBUILD_GIT_BRANCH_CLEAN" != 'main' ] ; then
    export DEPLOY_DIR="temp/branches/${CUSTOM_CODEBUILD_GIT_BRANCH_CLEAN}";
  else
    export DEPLOY_DIR='';
  fi
fi
echo CUSTOM_CODEBUILD_GIT_BRANCH_CLEAN = $CUSTOM_CODEBUILD_GIT_BRANCH_CLEAN
echo CUSTOM_CODEBUILD_GIT_PR = $CUSTOM_CODEBUILD_GIT_PR
echo DEPLOY_DIR = $DEPLOY_DIR

echo Deploy website static content to S3 Bucket

aws s3 cp public/ s3://${WEB_SITE_BUCKET}/${DEPLOY_DIR} --recursive
aws cloudfront create-invalidation --distribution-id ${CLOUDFRONT_DISTRO_ID} --paths /${DEPLOY_DIR}\*

#aws s3 sync public/ s3://${WEB_SITE_BUCKET}/${DEPLOY_DIR} --delete;
#aws cloudfront create-invalidation --distribution-id ${CLOUDFRONT_DISTRO_ID} --paths /${DEPLOY_DIR}\*
