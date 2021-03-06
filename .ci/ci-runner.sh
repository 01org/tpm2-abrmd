#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-2

set -exo pipefail

DOCKER_SCRIPT="docker.run"
COV_SCRIPT="coverity.run"

# Github has a default env variable GITHUB_REPOSITORY which contains the 
# repo owner and repo name in the <repo-owner>/<repo-name> format. Parse this
# and get the project name itself.
export PROJECT=$(echo $GITHUB_REPOSITORY | cut -d'/' -f 2-)
export DOCKER_BUILD_DIR="/workspace/$PROJECT"

# if no DOCKER_IMAGE is set, warn and default to fedora-30
if [ -z "$DOCKER_IMAGE" ]; then
  echo "WARN: DOCKER_IMAGE is not set, defaulting to fedora-30"
  export DOCKER_IMAGE="fedora-30"
fi

#
# Docker starts you in a cloned repo of your project with the PR checkout out.
# We want those changes IN the docker image, so use the -v option to mount the
# project repo in the docker image.
#
# Also, pass in any env variables required for the build via .ci/docker.env file
#
# Execute the build and test procedure by running .ci/docker.run
#

ci_env=""
if [ "$ENABLE_COVERAGE" == "true" ]; then
  ci_env=$(bash <(curl -s https://codecov.io/env))
fi


if [ "$ENABLE_COVERITY" == "true" ]; then
  echo "Running coverity build"
  script="$COV_SCRIPT"
else
  echo "Running non-coverity build"
  script="$DOCKER_SCRIPT"
fi

docker run --ulimit core=0 --cap-add=SYS_PTRACE $ci_env --env-file .ci/docker.env \
  -v "$(pwd):$DOCKER_BUILD_DIR" "ghcr.io/tpm2-software/$DOCKER_IMAGE" \
  /bin/bash -c "$DOCKER_BUILD_DIR/.ci/$script"

exit 0
