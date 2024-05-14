#!/bin/zsh

# Set configuration variables
BASE=$(dirname $(realpath $0))

pushd $(dirname $(dirname $BASE))  # root directory of the project
docker run --rm --gpus all \
-v ./example/input:/root/input \
-v ./example/output:/root/output \
chunan/esmfold:root-devel \
-i /root/input/1a2y-HLC.fasta \
-o /root/output/root-devel \
> ./example/logs/pred-root-devel.log  2>./example/logs/pred-root-devel.err
