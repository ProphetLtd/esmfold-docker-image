#!/bin/zsh

# Set configuration variables
BASE=$(dirname $(realpath $0))
trainModelsDir=/mnt/Data/trained_models/ESM2

pushd $(dirname $(dirname $BASE))  # root directory of the project
docker run --rm --gpus all \
-v ./example/input:/root/input \
-v ./example/output:/root/output \
-v $trainModelsDir:/root/.cache/torch/hub/checkpoints \
chunan/esmfold:root-runtime \
-i /root/input/1a2y-HLC.fasta \
-o /root/output/root-runtime \
> ./example/logs/pred-root-runtime.log  2>./example/logs/pred-root-runtime.err