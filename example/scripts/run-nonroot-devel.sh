#!/bin/zsh

# Set configuration variables
BASE=$(dirname $(realpath $0))

pushd $(dirname $(dirname $BASE))  # root directory of the project
docker run --rm --gpus all \
-v ./example/input:/home/vscode/input \
-v ./example/output:/home/vscode/output \
chunan/esmfold:nonroot-devel \
-i /home/vscode/input/1a2y-HLC.fasta \
-o /home/vscode/output/nonroot-devel \
> ./example/logs/pred-nonroot-devel.log  2>./example/logs/pred-nonroot-devel.err
