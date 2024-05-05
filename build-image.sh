#!/bin/zsh

BASE=$(dirname $(realpath $0))
REPONAME=esmfold-docker-image

# assert CWD basename is $REPONAME
if [[ $(basename $BASE) != $REPONAME ]]; then
    echo "Please run this script from the root of the repository."
    exit 1
fi

# ------------------------------------------------------------------------------
# Uncomment any of the following lines to
# build the image with a specific use case
# ------------------------------------------------------------------------------
# # build image, add non-root user
# docker build --no-cache -t $USER/esmfold:nonroot-devel -f Dockerfiles/Dockerfile.nonroot .

# # build runtime image, add non-root user
# docker build --no-cache -t $USER/esmfold:nonroot-runtime -f Dockerfiles/Dockerfile.nonroot.runtime .

# build image, root user only
docker build --no-cache -t $USER/esmfold:root-devel -f Dockerfiles/Dockerfile.root .

# # build runtime image, root user only
# docker build --no-cache -t $USER/esmfold:root-runtime -f Dockerfiles/Dockerfile.root.runtime .
